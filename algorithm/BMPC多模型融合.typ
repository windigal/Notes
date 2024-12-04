#import "../utils/template.typ": *
#import "../utils/diagbox.typ": *
#import "@preview/cuti:0.2.1": show-cn-fakebold
#show: show-cn-fakebold
#set par(justify: true)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)
#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
)
首次创建日期：2024-12-04

参考文档：#link("https://github.com/nicklashansen/tdmpc2/issues/18")

本文档记录在BMPC上测试多模型参数融合的实施。该issue提出同时运行多个agent，并每隔一定步数将模型参数求平均并更新到所有agent中，可以大大加速训练。以下是根据该思路进行的简单的实施。
= 加入定时模型存储
在online_trainer.py文件中，在eval之前加入模型存储。
```py
if self._step > self.cfg.seed_steps and \ 
    merge_next and self.cfg.do_model_merge:
    self._merge_dir = os.path.join(self.cfg.merge_model_dir,
                                    "step" + str(self._step))
    if not os.path.exists(self._merge_dir):
        os.makedirs(self._merge_dir)
    self.agent.save(self._merge_dir + "/" + str(self.cfg.seed) + ".pt")
    while (len(os.listdir(self._merge_dir)) != self.cfg.merge_num):
        time_for_sleep.sleep(0.1)
    self.merge()
    merge_next = False
```
= 加入模型融合
代码参考自issue
```py
def merge(self):
    """Merge the models."""
    state_time = time()
    assert len(os.listdir(self._merge_dir)) == self.cfg.merge_num, "Not all models are saved."
    model_names = ["_encoder", "_dynamics", "_reward", "_pi", "_Vs", "_target_Vs"]
    agents = []
    for ckpt in os.listdir(self._merge_dir):
        agent = BMPC(copy.deepcopy(self.cfg))
        agent.load(os.path.join(self._merge_dir, ckpt))
        agents.append(agent)
    for model_name in model_names:
        models = [getattr(a.model, model_name) for a in agents]
        with torch.no_grad():
            for name, param in getattr(self.agent.model, \ 
                                       model_name).named_parameters():
                params_to_merge = [model.state_dict()[name] \ 
                                   for model in models]
                mean_param = torch.mean(torch.stack(params_to_merge, \ 
                                                    dim=0), dim=0)
                param.data.copy_(mean_param)
    print("Success merging models, time: ", time() - state_time)
```
#text(red)[注意：在创建BMPC实例时，不能传入self.cfg，否则会更改配置文件，导致后续训练时间逐渐增加。应该传入copy.deepcopy(self.cfg)。]

= 加入过期模型删除线程
在train函数运行前，先启动一个删除线程，该线程会自动检测文件夹中的模型是否过期，只保留最新的两个模型。
```py
def delete_old_files():
    folder_path = cfg.merge_model_dir
    while True:
        folders = sorted(os.listdir(folder_path),
                          key=lambda x: os.path.getctime(os.path.join(folder_path, x)))
        if len(folders) > 2:
            for folder in folders[:-2]:
                folder_to_delete = os.path.join(folder_path, folder)
                if os.path.isdir(folder_to_delete):
                    shutil.rmtree(folder_to_delete)
                    print(f'Deleted: {folder}')
        time.sleep(100)
```