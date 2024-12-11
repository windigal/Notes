#import "../../../../utils/template.typ": *
#import "../../../../utils/diagbox.typ": *
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
首次创建日期：2024-12-7

*文件路径 `IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/direct/franka_cabinet/franka_cabinet_env.py` *

本文记录使用direct control的方式控制franka机械臂打开柜门的RL环境类，学习环境类的实现。

该文件共定义两个类：`FrankaCabinetEnvCfg`与`FrankaCabinetEnv`，分别为环境配置与环境类。

= *```python class FrankaCabinetEnvCfg(DirectRLEnvCfg)```*
该类中共有七个部分：env、simulation、scene、robot、cabinet、ground plane、reward scales

== *env*
```py
# env
episode_length_s = 8.3333  # 500 timesteps
decimation = 2
action_space = 9
observation_space = 23
state_space = 0
```
分别定义了episode时长、策略控制步长（action repeat）、动作空间维度、观测空间维度、状态空间维度（不需要）。

== *simulation*
```py
# simulation
sim: SimulationCfg = SimulationCfg(
    dt=1 / 120,
    render_interval=decimation,
    disable_contact_processing=True,
    physics_material=sim_utils.RigidBodyMaterialCfg(
        friction_combine_mode="multiply",
        restitution_combine_mode="multiply",
        static_friction=1.0,
        dynamic_friction=1.0,
        restitution=0.0))
```
分别定义了仿真模拟步长、渲染间隔、是否禁用接触处理、以及物理材质。其中物理材质定义了摩擦系数（动、静）、弹性系数。

== *scene*
```py
scene: InteractiveSceneCfg = InteractiveSceneCfg(num_envs=4096, env_spacing=3.0, replicate_physics=True)
```
定义了交互式场景的环境数量、环境间距、是否保持物理模拟一致。

== *robot*
一个资产配置通过一个`ArticulationCfg`类定义。该类需要传入四个参数：`prim_path`、`spawn`、`init_state`、`actuators`。

=== *prim_path*
```py
prim_path="/World/envs/env_.*/Robot"
```
定义资产在Isaac sim环境中的路径

=== *spawn*
```py
spawn=sim_utils.UsdFileCfg(
    usd_path=f"{ISAAC_NUCLEUS_DIR}/Robots/Franka/franka_instanceable.usd",
    activate_contact_sensors=False,
    rigid_props=sim_utils.RigidBodyPropertiesCfg(
        disable_gravity=False,
        max_depenetration_velocity=5.0,
    ),
    articulation_props=sim_utils.ArticulationRootPropertiesCfg(
        enabled_self_collisions=False, solver_position_iteration_count=12, solver_velocity_iteration_count=1
    ),
),
```
定义了资产的USD文件路径、是否激活接触传感器、刚体属性、关节属性。其中刚体属性定义了是否禁用重力、最大去穿透速度；关节属性定义了是否启用自碰撞、位置求解器迭代次数、速度求解器迭代次数。

=== *init_state*
```py
init_state=ArticulationCfg.InitialStateCfg(
    joint_pos={
        "panda_joint1": 1.157,
        "panda_joint2": -1.066,
        "panda_joint3": -0.155,
        "panda_joint4": -2.239,
        "panda_joint5": -1.841,
        "panda_joint6": 1.003,
        "panda_joint7": 0.469,
        "panda_finger_joint.*": 0.035,
    },
    pos=(1.0, 0.0, 0.0),
    rot=(0.0, 0.0, 0.0, 1.0),
),
```
定义了机械臂各个关节的初始角度，其中`panda_joint1` 到 `panda_joint7` 对应机械臂的七个主要关节，`panda_finger_joint.*`使用了通配符。`pos`表示机械臂基座在模拟环境中的初始位置(xyz三维坐标)，`rot`表示旋转(wxyz四元数)。

=== *actuators*
```py
actuators={
    "panda_shoulder": ImplicitActuatorCfg(
        joint_names_expr=["panda_joint[1-4]"],
        effort_limit=87.0,
        velocity_limit=2.175,
        stiffness=80.0,
        damping=4.0,
    ),
    "panda_forearm": ImplicitActuatorCfg(...),
    "panda_hand": ImplicitActuatorCfg(...)
}
```
定义了机械臂的三个隐式驱动器，分别对应机械臂的肩部、前臂、手部。其中`joint_names_expr`使用了正则表达式，表示驱动器作用的关节，`effort_limit`表示力矩限制，`velocity_limit`表示速度限制，`stiffness`表示刚度，`damping`表示阻尼。

== *cabinet*
与机械臂类似，定义了柜门的资产配置。此处不再赘述

== *ground plane*
```py
terrain = TerrainImporterCfg(
    prim_path="/World/ground",
    terrain_type="plane",
    collision_group=-1,
    physics_material=sim_utils.RigidBodyMaterialCfg(
        friction_combine_mode="multiply",
        restitution_combine_mode="multiply",
        static_friction=1.0,
        dynamic_friction=1.0,
        restitution=0.0,
    ),
)
action_scale = 7.5
dof_velocity_scale = 0.1
```
定义了地面的资产配置，包括路径、类型、碰撞组、物理材质。其中物理材质同sim中的设置（#text(red)[有什么区别？]）。`action_scale`表示动作缩放倍数，`dof_velocity_scale`表示自由度速度缩放。

== *reward scales*
```py
dist_reward_scale = 1.5
rot_reward_scale = 1.5
open_reward_scale = 10.0
action_penalty_scale = 0.05
finger_reward_scale = 2.0
```
定义了距离奖励、旋转奖励、打开奖励、动作惩罚、手指奖励的缩放倍数，用于奖励计算。

= *```python class FrankaCabinetEnv(DirectRLEnv)```*

该类继承自`DirectRLEnv`类。该类中定义了以下方法

== *```python def __init__(self, cfg: FrankaCabinetEnvCfg, render_mode: str | None = None, **kwargs)```*
