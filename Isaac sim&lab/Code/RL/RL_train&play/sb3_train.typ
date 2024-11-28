#import "../../../../utils/template.typ": *
#import "../../../../utils/diagbox.typ": *
#import "@preview/cuti:0.2.1": show-cn-fakebold
#show: show-cn-fakebold
#set par(justify: true)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)

首次创建日期：2024-11-25

*文件路径 `IsaacLab/source/standalone/workflows/sb3/train.py` 使用Stable-baselines3进行Isaac Sim 环境训练*

文件依次进行以下操作
1. 读入命令行参数
2. 启动omniverse
```python
# append AppLauncher cli args
AppLauncher.add_app_launcher_args(parser)
# parse the arguments
args_cli, hydra_args = parser.parse_known_args()
app_launcher = AppLauncher(args_cli)
simulation_app = app_launcher.app
```
3. 配置文件整理与保存
```python
dump_yaml(os.path.join(log_dir, "params", "env.yaml"), env_cfg)
dump_yaml(os.path.join(log_dir, "params", "agent.yaml"), agent_cfg)
dump_pickle(os.path.join(log_dir, "params", "env.pkl"), env_cfg)
dump_pickle(os.path.join(log_dir, "params", "agent.pkl"), agent_cfg)
```
4. 环境生成与包装
```python
  env = gym.make(args_cli.task, cfg=env_cfg, render_mode="rgb_array" if args_cli.video else None)
  env = Sb3VecEnvWrapper(env)
```
5. 智能体生成与训练
```python
  agent = PPO(policy_arch, env, verbose=1, **agent_cfg)
  new_logger = configure(log_dir, ["stdout", "tensorboard"])
  agent.set_logger(new_logger)
  checkpoint_callback = CheckpointCallback(save_freq=1000, save_path=log_dir, name_prefix="model", verbose=2)
  agent.learn(total_timesteps=n_timesteps, callback=checkpoint_callback)
```