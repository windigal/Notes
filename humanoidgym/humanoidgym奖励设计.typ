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
#align(center)[#text(size: 19pt, font: ("Times New Roman","SimHei"))[*Humanoidgym奖励设计*]] 
#align(center)[#text(size: 14pt)[2025-03-10]]
记录在Humanoidgym框架下乐聚Kuavo42人形机器人步行训练的奖励设计。无色表示仅原版奖励，#highlight(fill:red)[红色]表示仅乐聚版奖励，#highlight(fill:yellow)[黄色]表示两者均有。
= #highlight(fill:yellow)[*joint pos*]
该奖励计算当前关节位置和目标关节位置的差值，用于指导机器人关节位置的调整。
== 原版
目标关节位置来自于正弦函数拟合
```python
joint_pos = self.dof_pos.clone()
pos_target = self.ref_dof_pos.clone()
diff = joint_pos - pos_target
r = torch.exp(-2 * torch.norm(diff, dim=1)) - 0.2 * torch.norm(diff, dim=1).clamp(0, 0.5)
```
计算公式$r=e^(-2 norm(x))-min(max(norm(d)"/"5,0),0.5)$
== 乐聚版
目标关节位置来自一个预训练的步态模型。
```python
joint_pos = self.dof_pos.clone()
pos_target = self.ref_dof_pos.clone()
diff = joint_pos - pos_target
```
这里`joint_pos`的维度是`[num_envs, num_dof]`
```python
for idx in [0, 5, 6, 11]:
  diff[~self.commands[:, 4].bool(), idx] *= 0
diff[~self.commands[:, 4].bool(), 2] *= 0.5
diff[~self.commands[:, 4].bool(), 8] *= 0.5
```
[0, 5, 6, 11]分别是`leg_l1_joint`, `leg_l6_joint`, `leg_r1_joint`, `leg_r6_joint`，非站立状态不考虑这些关节？

[2, 8]分别是`leg_l3_joint`, `leg_r3_joint`.
```python
rew = torch.exp(-sigma * torch.norm(diff, dim=1))
rew[self.is_pushing] = 1
ratio = torch.clip(self.resample_cmd_length_buf * self.dt / self.cfg.rewards.cycle_time, 0, 1)
rew = rew * ratio + (1 - ratio)
```
rew最大奖励为1，有指令的时间考虑奖励，无指令默认为1？

= #highlight(fill:red)[*half_period*] 
该奖励暂时不清楚具体含义，可能是半周期奖励计算。
```python
target = self.period_history[name][0].clone()
target[self.commands[:, 4].to(bool)] = self.get_period_symmetric_value(name)[self.commands[:, 4].to(bool)].clone()
target[:, :12] = torch.roll(target[:, :12], shifts=6, dims=1)
target[:, 12:] = torch.roll(target[:, 12:], shifts=7, dims=1)
target[:, [0, 1, 5, 6, 7, 11]] *= -1
target[:, [13, 14, 16, 18, 20, 21, 23, 25]] *= -1
diff = self.get_period_symmetric_value(name) - target
```
这里`period_history`是半周期内关节位置的双端队列，`target`的维度为`[num_envs, num_dof]`。之后对关节位置顺序进行调整，简单来说就是左腿和右腿，左臂和右臂的关节位置互换（意义不明的操作）。

= #highlight(fill:yellow)[*foot slip*]
该奖励计算机器人脚部滑动的情况。
```python
contact = self.contact_forces[:, self.feet_indices, 2] > 5.
foot_speed_norm = torch.norm(self.rigid_state[:, self.feet_indices, 7:9], dim=2)
rew = torch.sqrt(foot_speed_norm)
rew *= contact
```
大于5认定为脚部接触地面，接触脚计算速度作为奖励。

= #highlight(fill:red)[*foot pos*]
不知道在干嘛
```python
stance_mask = self.contact_forces[:, self.feet_indices, 2] > 100.
measured_heights = torch.sum(
    self.rigid_state[:, self.feet_indices, 2] * stance_mask, dim=1) / torch.sum(stance_mask, dim=1) - self.cfg.rewards.foot_height
```
`measured_heights`是平均抬脚高度？
```python
left_pos_diff = self.rigid_state[:, 6, :3] - self.ref_body_positions["leg_l6_link"]
left_pos_diff[:, 2] -= measured_heights
right_pos_diff = self.rigid_state[:, 12, :3] - 
                 self.ref_body_positions["leg_r6_link"]
right_pos_diff[:, 2] -= measured_heights
```
没看懂为什么要arm_r1-leg_l6？？

= #highlight(fill:yellow)[*feet contact forces*]
限制脚与地面过高接触力，不包含摩擦力
== 原版
```python
return torch.sum((torch.norm(self.contact_forces[:, self.feet_indices, :], dim=-1) - self.cfg.rewards.max_contact_force).clip(0, 400), dim=1)
```
考虑了xyz三个方向的力
== 乐聚版
```python
contact_force = self.contact_forces[:, self.feet_indices, 2]
rew = (contact_force.sum(-1) - self.cfg.rewards.max_contact_force).clip(0, 400)
rew[self.episode_length_buf < 20] = 0
```
超出最大值max_contact_force(600)的部分作为惩罚，前20步不考虑奖励？

= #highlight(fill:red)[*tracking x lin vel*]
跟踪x轴线速度
```python
x_vel_error = torch.abs(self.commands[:, 0] - self.mean_vel[:, 0])
rew = torch.zeros(self.num_envs, device=self.device)
for sigma in self.cfg.rewards.x_tracking_sigmas:
    rew += torch.exp(-sigma * x_vel_error) / len(self.cfg.rewards.x_tracking_sigmas)
ref_instant_vel = self.commands[:, 0]
rew += torch.exp(-10 * torch.square(ref_instant_vel - self.base_lin_vel[:, 0]))
return rew / 2
```
这个mean_vel和base_lin_vel有什么区别？

= #highlight(fill:red)[*tracking y lin vel*]
同上

= *tracking_lin_vel*
```python
lin_vel_error = torch.sum(torch.square(
    self.commands[:, :2] - self.base_lin_vel[:, :2]), dim=1)
return torch.exp(-lin_vel_error * self.cfg.rewards.tracking_sigma)
```
直接MSE

= #highlight(fill:yellow)[*tracking ang vel*]
跟踪角速度，同上

= *vel mismatch exp*
保证速度平稳
```python
lin_mismatch = torch.exp(-torch.square(self.base_lin_vel[:, 2]) * 10)
ang_mismatch = torch.exp(-torch.norm(self.base_ang_vel[:, :2], dim=1) * 5.)
c_update = (lin_mismatch + ang_mismatch) / 2.
```
速度越小越好？

= #highlight(fill:yellow)[*low speed*]
虽然是low speed，但是考虑了速度过小、过大、方向不匹配的情况
```python
absolute_speed = torch.abs(self.base_lin_vel[:, 0])
absolute_command = torch.abs(self.commands[:, 0])

speed_too_low = absolute_speed < 0.5 * absolute_command
speed_too_high = absolute_speed > 1.2 * absolute_command
speed_desired = ~(speed_too_low | speed_too_high)
# Check if the speed and command directions are mismatched
sign_mismatch = torch.sign(
    self.base_lin_vel[:, 0]) != torch.sign(self.commands[:, 0])
reward = torch.zeros_like(self.base_lin_vel[:, 0])
reward[speed_too_low] = -1.0
reward[speed_too_high] = 0.
reward[speed_desired] = 1.2
reward[sign_mismatch] = -2.0
return reward * (self.commands[:, 0].abs() > 0.1)
```
当前速度大小在指令速度大小的0.5-1.2之间为合适速度，过小惩罚更严重，方向错误惩罚最严重。速度指令过小时不考虑该奖励。

= *feet air time*


= #highlight(fill:yellow)[*orientation*]
保证机器人的朝向
```python
quat_mismatch = torch.exp(-torch.sum(torch.abs(self.base_euler_xyz[:, :2]), dim=1) * 10)
orientation = torch.exp(-torch.norm(self.projected_gravity[:, :2], dim=1) * 20)
return (quat_mismatch + orientation) / 2
```
orientation防止身体倾斜，quat_mismatch防止机器人自身旋转过大（例如减少扭腰？）

= *base height*
维持机器人高度
```python
stance_mask = self.contact_forces[:, self.feet_indices, 2] > 100.
measured_heights = torch.sum(
    self.rigid_state[:, self.feet_indices, 2] * stance_mask, dim=1) / torch.sum(stance_mask, dim=1) - self.cfg.rewards.foot_height
measured_heights[torch.isnan(measured_heights)] = 0
base_height = self.root_states[:, 2] - measured_heights
rew = torch.exp(-torch.abs(base_height - self.ref_height) * 20)
```
当前root高度减去抬脚高度，和目标高度尽量接近？

= *base acc*
维持机器人速度与加速度平稳
```python
root_acc = self.last_root_vel - self.root_states[:, 7:13]
rew = torch.exp(-torch.norm(root_acc, dim=1) * 3)
```
猜测是根据前后两帧的速度和加速度差值计算的奖励，需要搞清楚root_states每一维是什么。

= *feet clearance*
鼓励在步态摆动阶段抬脚。
```python
contact = self.contact_forces[:, self.feet_indices, 2] > 5.
feet_z = self.rigid_state[:, self.feet_indices, 2] - 0.05
delta_z = feet_z - self.last_feet_z
self.feet_height += delta_z
self.last_feet_z = feet_z
swing_mask = 1 - self._get_gait_phase()
rew_pos = torch.abs(self.feet_height - self.cfg.rewards.target_feet_height) < 0.01
rew_pos = torch.sum(rew_pos * swing_mask, dim=1)
self.feet_height *= ~contact
```

= #highlight(fill:yellow)[*feet contact same*]
根据与步态阶段对齐的脚接触次数计算奖励，取决于脚接触是否与预期的步态阶段相匹配
```python
contacts = torch.stack([self.contact_history[i] for i in range(len(self.contact_history))], dim=1)
mean_force = contacts.mean(dim=1)
diff1 = (mean_force[:, 0] - mean_force[:, 1])
diff2 = (contacts[:, -1] - contacts[:, -self.contact_history.maxlen // 2]).sum(-1)
rew1 = torch.exp(- 0.01 * diff1.abs())
rew2 = torch.exp(- 0.01 * diff2.abs())
return (rew1 + rew2) / 2
```
diff1直接计算两脚平均接触力是否一致，diff2比较最后时刻与之前中间时刻的接触力是否一致

= #highlight(fill:yellow)[*action smoothness*]
维持前后帧动作平滑
```python
term_1 = torch.sum(torch.square(
    self.last_actions - self.actions), dim=1)
term_2 = torch.sum(torch.square(
    self.actions + self.last_last_actions - 2 * self.last_actions), dim=1)
term_3 = 0.05 * torch.sum(torch.abs(self.actions), dim=1)
return term_1 + term_2 + term_3
```
`term_1`前后帧动作差值，`term_2`前后帧动作差值的差值，`term_3`动作大小

= #highlight(fill:yellow)[*torques*]
最小化关节扭矩
== 原版
```python
torch.sum(torch.square(self.torques), dim=1)
```
== 乐聚版
```python
weight = torch.tensor([1, 1, 1, 1, 2, 3] * 2 + [1] * 14, device=self.device)
rew = torch.sum(torch.square(self.torques * weight), dim=1)
rew[self.is_pushing] /= 3
```
着重关注`l5`, `l6`, `r5`, `r6`的扭矩

= #highlight(fill:yellow)[*dof vel*]
== 原版
```python
return torch.sum(torch.square(self.dof_vel), dim=1)
```
== 乐聚版
最小化关节速度
```python
weight = torch.tensor([3, 3, 1, 1, 1, 3] * 2 + [1] * 14, device=self.device)
rew = torch.sum(torch.square(self.dof_vel * weight), dim=1)
```
着重关注`l1`, `l2`, `l6`, `r1`, `r2`, `r6`的速度

= #highlight(fill:yellow)[*dof acc*]
最小化关节加速度
```python
return torch.sum(torch.square((self.dof_vel - self.last_dof_vel) / self.dt), dim=1)
```
数值计算加速度

