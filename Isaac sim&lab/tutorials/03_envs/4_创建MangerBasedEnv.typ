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
#align(center)[#text(size: 19pt, font: "SimHei")[*创建*]#text(size: 19pt)[*ManagerBasedEnv #footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/03_envs/create_manager_base_env.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-12]]

本文记录基于管理器方式创建Cartpole环境的过程#footnote[IsaacLab/source/standalone/tutorials/03_envs/create_cartpole_base_env.py]

= *定义动作*
动作管理器中可以包含多个`managers.ActionTerm`对象
```py
@configclass
class ActionsCfg:
    """Action specifications for the environment."""
    joint_efforts = mdp.JointEffortActionCfg(asset_name="robot", 
                                             joint_names=["slider_to_cart"], 
                                             scale=5.0)
```
cartpole环境的动作施加到小车上来控制杆的平衡，因此在slider_to_cart关节（滑动关节）上施加力，维度为1

= *定义观测*
观测管理器可以包含多个观测组，来定义环境的不同观测空间。在本环境中，只定义了名为`policy`的观测组
```py
@configclass
class ObservationsCfg:
    @configclass
    class PolicyCfg(ObsGroup):
        # observation terms (order preserved)
        joint_pos_rel = ObsTerm(func=mdp.joint_pos_rel)
        joint_vel_rel = ObsTerm(func=mdp.joint_vel_rel)
        def __post_init__(self) -> None:
            self.enable_corruption = False
            self.concatenate_terms = True
    policy: PolicyCfg = PolicyCfg()
```
观测组继承自`managers.ObservationGroupCfg`类，观测项通过实例化`managers.ObsTerm`类来定义。在初始化函数中，可以选择是否加入观测噪声并启用观测连接来将观测项连接成为一个向量。

#text(red)[注意：在这里ObsTerm并没有传入要观测的物体，是因为`mdp.joint_pos_rel`函数的参数`asset_cfg`默认为`SceneEntityCfg("robot")`，且`CartpoleSceneCfg`类中也将Cartpole加入`"{ENV_REGEX_NS}/Robot"`，故自定义环境时需注意传入观测物体]

= *定义事件*
事件包括随机reset场景，模拟过程中固定频率的操作，以及场景启动的时候的操作。每一个事件项通过实例化`managers.EventTerm`类来定义，Isaac Lab提供了三种常用的模式：`startup`仅在环境启动的时候进行, `reset`当环境终止和重置的时候发生的事件, `interval`在给定间隔后执行的时事件。
```py
@configclass
class EventCfg:
    add_pole_mass = EventTerm(
        func=mdp.randomize_rigid_body_mass,
        mode="startup",
        params={
            "asset_cfg": SceneEntityCfg("robot", body_names=["pole"]),
            "mass_distribution_params": (0.1, 0.5),
            "operation": "add"})
    reset_cart_position = EventTerm(
        func=mdp.reset_joints_by_offset,
        mode="reset",
        params={
            "asset_cfg": SceneEntityCfg("robot", 
										joint_names=["slider_to_cart"]),
            "position_range": (-1.0, 1.0),
            "velocity_range": (-0.1, 0.1)})
    reset_pole_position = EventTerm(
        func=mdp.reset_joints_by_offset,
        mode="reset",
        params={
            "asset_cfg": SceneEntityCfg("robot",
										joint_names=["cart_to_pole"]),
            "position_range": (-0.125 * math.pi, 0.125 * math.pi),
            "velocity_range": (-0.01 * math.pi, 0.01 * math.pi)})
```

= *场景组合*
通过继承`managers.ManagerBasedEnv`类，可以将动作、观测和事件组合在一起。
```py
@configclass
class CartpoleEnvCfg(ManagerBasedEnvCfg):
    scene = CartpoleSceneCfg(num_envs=1024, env_spacing=2.5)
    observations = ObservationsCfg()
    actions = ActionsCfg()
    events = EventCfg()

    def __post_init__(self):
        """Post initialization."""
        self.viewer.eye = [4.5, 0.0, 6.0]
        self.viewer.lookat = [0.0, 0.0, 2.0]
        self.decimation = 4  # env step every 4 sim steps: 200Hz / 4 = 50Hz
        # simulation settings
        self.sim.dt = 0.005  # sim step every 5ms: 200Hz
```

= *模拟循环*
将定义的`CartpoleEnvCfg`实例传入`managers.ManagerBasedEnv`类中，即可创建Cartpole环境，每次传入随机动作进行模拟
```py
def main():
    env_cfg = CartpoleEnvCfg()
    env_cfg.scene.num_envs = args_cli.num_envs
    env = ManagerBasedEnv(cfg=env_cfg)
    count = 0
    while simulation_app.is_running():
        with torch.inference_mode():
            # reset
            if count % 300 == 0:
                count = 0
                env.reset()
                print("-" * 80)
                print("[INFO]: Resetting environment...")
            joint_efforts = torch.randn_like(env.action_manager.action)
            obs, _ = env.step(joint_efforts)
            print("[Env 0]: Pole joint: ", obs["policy"][0][1].item())
            count += 1
    env.close()
```

= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/03_envs/create_cartpole_base_env.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。
#figure(image("imgs/managerbased.gif", width: 100%), numbering: none)