#import "@preview/cuti:0.2.1": show-cn-fakebold
#set text(size: 12pt)
#show: show-cn-fakebold
#set par(leading: 1.5em, justify: true,)
#set page(numbering: "1", number-align: center, margin: (x: 4em))
#set heading(numbering: "1.1")
#set footnote.entry(indent: 0em)
#show heading.where(level: 1): set block(below: 1.2em)
#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
)
#align(center)[#text(size: 19pt, font: ("Times New Roman","SimHei"))[*使用Isaac Lab框架训练已有环境*]#text(size: 19pt)[*#footnote[https://docs.robotsfan.com/isaaclab/source/overview/reinforcement-learning/rl_existing_scripts.html]*]] 

\
*注意：第一次训练某个环境，需要挂梯子进行资产下载，之后训练则可以直连，挂梯子教程参考 ./else/服务器与docker挂梯子.typ*

= *使用Isaac Lab框架训练已有环境*
Isaac Lab目前继承了四种强化学习训练框架：RL-Games、RSL-RL、SKRL与Stable-Baselines3

== *Stable-Baselines3*
```bash
conda activate isaaclab
python ~/IsaacLab/source/standalone/workflows/sb3/train.py --task Isaac-Cartpole-v0 --headless --device cpu
```

= *训练环境与智能体的config获取方式*

在训练的主函数main中，通过\
```python @hydra_task_config(args_cli.task, "xxx_cfg_entry_point")```进行装饰，该装饰器本质上是根据提供的task寻找对应的`env_cfg`文件，通过task和benchmark的组合，找到`agent_cfg`文件。其中xxx可以是四种训练框架中的任意一种。

`env_cfg`文件本质是每个任务独有的环境`Cfg`类的一个实例化，这些类位于```bash IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/manager_based/classic/${task_name}/${task_name}\_cfg.py```中。

`agent_cfg`文件位于```bash IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/manager_based/classic/${task_name}/agent/${algo_name}\_cfg.py```中。

#text(red)[*目前暂不清楚如何通过训练接口获取到这些config，但是可以通过查看源码找到对应的文件，然后手动修改。*]