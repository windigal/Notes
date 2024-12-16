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
#align(center)[#text(size: 19pt, font: "SimHei")[*创建*]#text(size: 19pt)[*ManagerBasedRLEnv #footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/03_envs/create_manager_rl_env.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-13]]
本文记录基于管理器方式创建Cartpole强化学习环境的过程#footnote[IsaacLab/source/standalone/tutorials/03_envs/run_cartpole_rl_env.py] #footnote[IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/manager_based/classic/ cartpole/cartpole_env_cfg.py]

= *定义奖励*
奖励管理器中可以包含多个`managers.RewardTermCfg`对象。Cartpole强化学习环境一共包含五个奖励项，分别为`alive`、`terminating`、`pole_pos`、`cart_vel`、`pole_vel`。
```py
@configclass
class RewardsCfg:
    alive = RewTerm(func=mdp.is_alive, weight=1.0)
    terminating = RewTerm(func=mdp.is_terminated, weight=-2.0)
    pole_pos = RewTerm(
        func=mdp.joint_pos_target_l2,
        weight=-1.0,
        params={"asset_cfg": SceneEntityCfg("robot", 
                            joint_names=["cart_to_pole"]), "target": 0.0})
    cart_vel = RewTerm(
        func=mdp.joint_vel_l1,
        weight=-0.01,
        params={"asset_cfg": SceneEntityCfg("robot", 
                            joint_names=["slider_to_cart"])})
    pole_vel = RewTerm(
        func=mdp.joint_vel_l1,
        weight=-0.005,
        params={"asset_cfg": SceneEntityCfg("robot", 
                            joint_names=["cart_to_pole"])})
```
`params`将作为参数传入func函数，用来指定计算奖励的物体与关节。`joint_pos_target_l2`计算关节与目标位置的偏离角度的l2范数，`joint_vel_l1`计算关节的速度的`l1`范数。奖励设计的目的为：
- *存活奖励*: 鼓励智能体尽可能长时间保持存活状态。
- *终止奖励*: 同样惩罚智能体的终止。
- *杆角度奖励*: 鼓励智能体保持杆在期望的直立位置。
- *小车速度奖励*: 鼓励智能体尽可能保持小车速度较小。
- *杆速度奖励*: 鼓励智能体尽可能保持杆速度较小。

= *定义Episode终止*
如果智能体到达不稳定或者不安全的状态，会进行回合终止，如果回合长度达到最大长度则也会终止。回合终止项由`managers.TerminationTermCfg`类实例定义。
```py
@configclass
class TerminationsCfg:
    time_out = DoneTerm(func=mdp.time_out, time_out=True)
    cart_out_of_bounds = DoneTerm(
        func=mdp.joint_pos_out_of_manual_limit,
        params={"asset_cfg": SceneEntityCfg("robot", 
                                            joint_names=["slider_to_cart"]), 
                                            "bounds": (-3.0, 3.0)})
```
`mdp.joint_pos_out_of_manual_limit`函数允许用户自定义限制范围

= *环境组合*
在`CartpoleEnvCfg`类中加入奖励和终止的Cfg类实例
```py
@configclass
class CartpoleEnvCfg(ManagerBasedRLEnvCfg):
    scene: CartpoleSceneCfg = CartpoleSceneCfg(num_envs=4096, env_spacing=4.0)
    observations: ObservationsCfg = ObservationsCfg()
    actions: ActionsCfg = ActionsCfg()
    events: EventCfg = EventCfg()
    rewards: RewardsCfg = RewardsCfg()
    terminations: TerminationsCfg = TerminationsCfg()
    def __post_init__(self) -> None:
        self.decimation = 2
        self.episode_length_s = 5
        self.viewer.eye = (8.0, 0.0, 5.0)
        self.sim.dt = 1 / 120
        self.sim.render_interval = self.decimation
```

= *模拟循环*
将定义的`CartpoleEnvCfg`实例传入`managers.ManagerBasedRLEnv`类中，即可创建Cartpole强化学习环境，每次传入随机动作进行模拟
```py
def main():
    env_cfg = CartpoleEnvCfg()
    env_cfg.scene.num_envs = args_cli.num_envs
    env = ManagerBasedRLEnv(cfg=env_cfg)
    count = 0
    while simulation_app.is_running():
        with torch.inference_mode():za's
            if count % 300 == 0:
                count = 0
                env.reset()
                print("-" * 80)
                print("[INFO]: Resetting environment...")
            joint_efforts = torch.randn_like(env.action_manager.action)
            obs, rew, terminated, truncated, info = env.step(joint_efforts)
            print("[Env 0]: Pole joint: ", obs["policy"][0][1].item())
            count += 1
    env.close()
```

= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/03_envs/run_cartpole_rl_env.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。
#figure(image("imgs/managerbased.gif", width: 100%), numbering: none)