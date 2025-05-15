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
#align(center)[#text(size: 19pt, font: ("Times New Roman","SimHei"))[*Humanoidgym代码框架*]] 
#align(center)[#text(size: 14pt)[2025-03-10]]
记录在Humanoidgym框架的模拟仿真代码细节。
= 模拟步长与周期
```python
self.dt = self.cfg.control.decimation * self.sim_params.dt
self.max_episode_length_s = self.cfg.env.episode_length_s
self.max_episode_length = np.ceil(self.max_episode_length_s / self.dt)
cycle_time = self.cfg.rewards.cycle_time
phase = self.episode_length_buf * self.dt / cycle_time
```
`dt`是策略控制周期，`max_episode_length_s`是一次仿真最长时间（单位秒），`max_episode_length`是一次仿真最大步数，`cycle_time`是周期时间，`phase`是当前周期的相位。

= 步态设计与参考状态
```python
phase = self._get_phase()
sin_pos = torch.sin(2 * torch.pi * phase)
# Add double support phase
stance_mask = torch.zeros((self.num_envs, 2), device=self.device)
# left foot stance
stance_mask[:, 0] = sin_pos >= 0
# right foot stance
stance_mask[:, 1] = sin_pos < 0
# Double support phase
stance_mask[torch.abs(sin_pos) < 0.1] = 1
```
根据当前帧的相位，计算正弦值，根据正弦值判断左脚或右脚支撑，`stance_mask`是一个`[num_envs, 2]`的张量，支撑为1，抬脚为0，在换脚支撑的时间内均为1。一个周期内先右脚抬起，后左脚抬起。

```python 
phase = self._get_phase()
sin_pos = torch.sin(2 * torch.pi * phase)
sin_pos_l = sin_pos.clone()
sin_pos_r = sin_pos.clone()
self.ref_dof_pos = torch.zeros_like(self.dof_pos)
scale_1 = self.cfg.rewards.target_joint_pos_scale
scale_2 = 2 * scale_1
# left foot stance phase set to default joint pos
sin_pos_l[sin_pos_l > 0] = 0
self.ref_dof_pos[:, 2] = sin_pos_l * scale_1
self.ref_dof_pos[:, 3] = sin_pos_l * scale_2
self.ref_dof_pos[:, 4] = sin_pos_l * scale_1
# right foot stance phase set to default joint pos
sin_pos_r[sin_pos_r < 0] = 0
self.ref_dof_pos[:, 8] = sin_pos_r * scale_1
self.ref_dof_pos[:, 9] = sin_pos_r * scale_2
self.ref_dof_pos[:, 10] = sin_pos_r * scale_1
# Double support phase
self.ref_dof_pos[torch.abs(sin_pos) < 0.1] = 0
```
根据当前帧的相位，计算某些关节的位置。234是左腿的大腿俯仰，膝盖，以及脚踝俯仰，8-10是右腿的大腿俯仰，膝盖，以及脚踝俯仰。训练仅开放了腿上的十二个关节，人形直线走路理论上只需要这六个关节，转向时除外。

= 指令结构与生成
指令有四维，分别是x轴线速度`lin_vel_x`, y轴线速度`lin_vel_y`, 偏航角速度`ang_vel_yaw`, 朝向`heading`。在未启动`heading_command`时，不考虑heading指令，启动`heading_command`指令后，通过当前朝向和目标朝向偏差计算偏航角速度。
```python
cmds[env_ids, 0] = rand(cmd_ranges["lin_vel_x"][0], cmd_ranges["lin_vel_x"][1])
cmds[env_ids, 1] = rand(cmd_ranges["lin_vel_y"][0], cmd_ranges["lin_vel_y"][1])
if cfg.cmds.heading_command:
    cmds[env_ids, 3] = rand(cmd_ranges["heading"][0], cmd_ranges["heading"][1])
else:
    cmds[env_ids, 2]=rand(cmd_ranges["ang_vel_yaw"][0],cmd_ranges["ang_vel_yaw"][1])
cmds[env_ids, :2] *= (torch.norm(cmds[env_ids, :2], dim=1) > 0.2)
```
```python
if cfg.commands.heading_command:
    forward = quat_apply(base_quat, forward_vec)
    heading = torch.atan2(forward[:, 1], forward[:, 0])
    cmds[:, 2] = torch.clip(0.5*wrap_to_pi(cmds[:, 3] - heading), -1., 1.)
```
当检测到速度跟踪奖励学习较好时，提升指令的随机范围进行课程学习
```python
if torch.mean(episode_sums["tracking_lin_vel"][env_ids]) /  
    max_episode_length > 0.8 * reward_scales["tracking_lin_vel"]:
    cmd_ranges["lin_vel_x"][0] = clip(cmd_ranges["lin_vel_x"][0] - 0.5, -cfg.commands.max_curriculum, 0.)
    cmd_ranges["lin_vel_x"][1] = clip(cmd_ranges["lin_vel_x"][1] + 0.5, 0., cfg.commands.max_curriculum)
```

= 环境随机性
在训练中，通过将随机的速度和角速度写入机器人质心状态中来模拟推动。
```python
max_vel = self.cfg.domain_rand.max_push_vel_xy
max_push_angular = self.cfg.domain_rand.max_push_ang_vel
self.rand_push_force[:, :2] = torch_rand_float(
    -max_vel, max_vel, (self.num_envs, 2), device=self.device)
self.root_states[:, 7:9] = self.rand_push_force[:, :2]
self.rand_push_torque = torch_rand_float(
    -max_push_angular, max_push_angular, (self.num_envs, 3), device=self.device)
self.root_states[:, 10:13] = self.rand_push_torque
self.gym.set_actor_root_state_tensor(
    self.sim, gymtorch.unwrap_tensor(self.root_states))
```
在创建环境时，随机每个环境的摩擦系数
```python
if self.cfg.domain_rand.randomize_friction:
    if env_id==0:
        friction_range = self.cfg.domain_rand.friction_range
        num_buckets = 256
        bucket_ids = torch.randint(0, num_buckets, (self.num_envs, 1))
        friction_buckets = torch_rand_float(friction_range[0], friction_range[1])
        self.friction_coeffs = friction_buckets[bucket_ids]
    for s in range(len(props)):
        props[s].friction = self.friction_coeffs[env_id]
    self.env_frictions[env_id] = self.friction_coeffs[env_id]
```
训练过程中，模拟动作随机传递延迟和噪声
```python
actions = clip(actions, -cfg.norm.clip_actions, self.cfg.norm.clip_actions)
delay = rand((self.num_envs, 1)) * self.cfg.domain_rand.action_delay
actions = (1 - delay) * actions + delay * self.actions
actions += self.cfg.domain_rand.action_noise * torch.randn_like(actions) * actions
```
