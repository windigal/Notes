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
#align(center)[#text(size: 19pt)[*Velocity-Flat-H1-v0*]] 
#align(center)[#text(size: 14pt)[2025-01-11]]

本文记录了Velocity-Flat-H1-v0环境的观测与奖励

= *观测*
#align(center)[#table(
  columns: 3,
  stroke: none,
  inset: (8pt, 10pt),
  align: center+horizon,
  table.hline(),
  table.header([名称], [维度], [描述]), 
  table.hline(),
  [base_lin_vel], [3], [基础线速度],
  [base_ang_vel], [3], [基础角速度],
  [projected_gravity], [3], [投影重力],
  [velocity_commands], [3], [速度指令],
  [joint_pos], [19], [关节位置],
  [joint_vel], [19], [关节速度],
  [actions], [19], [上一帧动作],
  table.hline(),
)]

= *奖励*
#align(center)[#table(
  columns: 3,
  stroke: none,
  inset: (8pt, 10pt),
  align: center+horizon,
  table.hline(),
  table.header([名称], [权重], [描述]), 
  table.hline(),
  [track_lin_vel_xy_exp], [1.0], [xy线速度误差奖励],
  [track_ang_vel_z_exp], [1.0], [z角速度误差奖励],
  [ang_vel_xy_l2], [-0.05], [xy平面角速度惩罚],
  [dof_torques_l2], [0.0], [关节力矩惩罚],
  [dof_acc_l2], [-1.25e-7], [关节加速度惩罚],
  [action_rate_l2], [-0.005], [动作变化速率惩罚],
  [feet_air_time], [1.0], [抬脚奖励],
  [flat_orientation_l2], [-1.0], [投影重力向量xy分量惩罚],
  [dof_pos_limits], [-1.0], [脚踝关节超出限制惩罚],
  [termination_penalty], [-200.0], [非超时异常终止惩罚],
  [feet_slide], [-0.25], [脚在地面滑动惩罚],
  [joint_deviation_hip], [-0.2], [髋关节偏离默认位置惩罚],
  [joint_deviation_arms], [-0.1], [手臂关节偏离默认位置惩罚],
  [joint_deviation_torso], [-0.1], [躯干关节偏离默认位置惩罚],
  table.hline(),
)]