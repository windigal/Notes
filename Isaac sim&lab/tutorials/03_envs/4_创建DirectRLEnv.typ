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
#align(center)[#text(size: 19pt, font: "SimHei")[*创建*]#text(size: 19pt)[*DirectRLEnv #footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/03_envs/create_direct_rl_env.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-16]]

本文记录直接工作流方式创建Cartpole强化学习环境的过程#footnote[IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/direct/cartpole/cartpole_env.py]。
= *基本配置*
将一些基本的配置数据写入一个类中，如`CartpoleEnvCfg`类，用于定义场景的一些基本参数，类似于读入的yaml或json配置文件，也可以写在主类初始化时。
```py
@configclass
class CartpoleEnvCfg(DirectRLEnvCfg):
    # env
    decimation = 2
    episode_length_s = 5.0
    action_scale = 100.0  # [N]
    action_space = 1
    observation_space = 4
    state_space = 0
    sim: SimulationCfg = SimulationCfg(dt=1 / 120, 
                                       render_interval=decimation)
    robot_cfg: ArticulationCfg = CARTPOLE_CFG.replace(prim_path="/World/envs/env_.*/Robot")
    cart_dof_name = "slider_to_cart"
    pole_dof_name = "cart_to_pole"
    scene: InteractiveSceneCfg = InteractiveSceneCfg(num_envs=4096, 
                                                     env_spacing=4.0, 
                                                     replicate_physics=True)
    max_cart_pos = 3.0  # the cart is reset if it exceeds that position [m]
    initial_pole_angle_range = [-0.25, 0.25]  # the range in which the pole angle is sampled from on reset [rad]
    # reward scales
    rew_scale_alive = 1.0
    rew_scale_terminated = -2.0
    rew_scale_pole_pos = -1.0
    rew_scale_cart_vel = -0.01
    rew_scale_pole_vel = -0.005
```

= *场景创建*
主环境类需要继承`DirectRLEnv`类，并且需要实现一些必要的抽象方法，如创建场景
```py
@configclass
def _setup_scene(self):
    self.cartpole = Articulation(self.cfg.robot_cfg)
    spawn_ground_plane(prim_path="/World/ground", cfg=GroundPlaneCfg())
    self.scene.clone_environments(copy_from_source=False)
    self.scene.filter_collisions(global_prim_paths=[])
    self.scene.articulations["cartpole"] = self.cartpole
    light_cfg = sim_utils.DomeLightCfg(intensity=2000.0, 
                                       color=(0.75, 0.75, 0.75))
    light_cfg.func("/World/Light", light_cfg)
```
在自定义环境类时，需要一些生成函数来将地面生成到场景中

= *动作交互*
需要实现`_pre_physics_step`和`_apply_action`方法，分别用于处理动作和应用动作
```py
def _pre_physics_step(self, actions: torch.Tensor) -> None:
    self.actions = self.action_scale * actions.clone()

def _apply_action(self) -> None:
    self.cartpole.set_joint_effort_target(self.actions, 
                                          joint_ids=self._cart_dof_idx)
```
在`step`函数中，每次调用`_pre_physics_step`方法将动作存到类变量中，之后执行`decimation`次`_apply_action`方法来进行物理动作与环境的交互

= *定义观测*
实现`_get_oberservation`方法，用于获取观测数据，需要手动进行cat
```py
def _get_observations(self) -> dict:
    obs = torch.cat(
        (
            self.joint_pos[:, self._pole_dof_idx[0]].unsqueeze(dim=1),
            self.joint_vel[:, self._pole_dof_idx[0]].unsqueeze(dim=1),
            self.joint_pos[:, self._cart_dof_idx[0]].unsqueeze(dim=1),
            self.joint_vel[:, self._cart_dof_idx[0]].unsqueeze(dim=1),
        ),
        dim=-1,
    )
    observations = {"policy": obs}
    return observations
```
最后需要以字典形式返回

= *定义奖励*
实现`_get_rewards`方法，用于获取奖励，计算类似于ManagerBasedRLEnv中的奖励计算
```py
def _get_rewards(self) -> torch.Tensor:
    total_reward = compute_rewards(
        self.cfg.rew_scale_alive,
        self.cfg.rew_scale_terminated,
        self.cfg.rew_scale_pole_pos,
        self.cfg.rew_scale_cart_vel,
        self.cfg.rew_scale_pole_vel,
        self.joint_pos[:, self._pole_dof_idx[0]],
        self.joint_vel[:, self._pole_dof_idx[0]],
        self.joint_pos[:, self._cart_dof_idx[0]],
        self.joint_vel[:, self._cart_dof_idx[0]],
        self.reset_terminated,
    )
    return total_reward
def compute_rewards(...) -> torch.Tensor:
    ...
    return total_reward
```

= *定义Episode终止与环境终止*
实现`_get_dones`方法，需要返回两个布尔张量，分别表示是否超出环境限制终止，以及是否达到最大回合长度终止
```py
def _get_dones(self) -> tuple[torch.Tensor, torch.Tensor]:
    self.joint_pos = self.cartpole.data.joint_pos
    self.joint_vel = self.cartpole.data.joint_vel
    time_out = self.episode_length_buf >= self.max_episode_length
    out_of_bounds = torch.any(
                             torch.abs(self.joint_pos[:, self._cart_dof_idx])
                             > self.cfg.max_cart_pos,
                             dim=1)
    out_of_bounds = out_of_bounds | torch.any(
        torch.abs(self.joint_pos[:, self._pole_dof_idx]) 
        > math.pi / 2, dim=1)
    return out_of_bounds, time_out
```
环境会自动计算需要初始化的`env_ids`并传入`_reset_idx`方法中，将需要重置的环境的新状态设置到模拟中
```py
def _reset_idx(self, env_ids: Sequence[int] | None):
    if env_ids is None:
        env_ids = self.cartpole._ALL_INDICES
    super()._reset_idx(env_ids)
    joint_pos = self.cartpole.data.default_joint_pos[env_ids]
    joint_pos[:, self._pole_dof_idx] += sample_uniform(
        self.cfg.initial_pole_angle_range[0] * math.pi,
        self.cfg.initial_pole_angle_range[1] * math.pi,
        joint_pos[:, self._pole_dof_idx].shape,
        joint_pos.device,
    )
    joint_vel = self.cartpole.data.default_joint_vel[env_ids]
    default_root_state = self.cartpole.data.default_root_state[env_ids]
    default_root_state[:, :3] += self.scene.env_origins[env_ids]
    self.joint_pos[env_ids] = joint_pos
    self.joint_vel[env_ids] = joint_vel

    self.cartpole.write_root_pose_to_sim(default_root_state[:, :7], 
                                         env_ids)
    self.cartpole.write_root_velocity_to_sim(default_root_state[:, 7:], 
                                             env_ids)
    self.cartpole.write_joint_state_to_sim(joint_pos, joint_vel, 
                                           None, env_ids)
```
这里进行了初始位置的随机化，并将根状态的位置加上初始位置，最后将新的状态写入模拟中


= *可视化*
```sh
python source/standalone/workflows/rl_games/train.py --task=Isaac-Cartpole-Direct-v0 --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。
#figure(image("imgs/directbased.gif", width: 100%), numbering: none)