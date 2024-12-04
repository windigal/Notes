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
首次创建日期：2024-12-01

先导文档：1\_将BMPC算法移植入Isaac Lab框架中.typ

由于Isaac sim环境存在terminal的情况，BMPC训练效果不佳。本文记录将环境更改为超时结束的方式。

注意：使用环境均为直接式的环境（DirectRLEnv），以cartpole-direct-v0为例

1. 在直接式环境类DirectRLEnv的step函数中，修改reset_buf为reset.time_outs，即不考虑环境中断导致的reset
```py
# self.reset_buf = self.reset_terminated | self.reset_time_outs
self.reset_buf = self.reset_time_outs
```
2. 在Cartpole环境类CartpoleEnv的函数\_get_dones中，修改time_out（只是为了输出整齐）
```py
# time_out = self.episode_length_buf >= self.max_episode_length - 1
time_out = self.episode_length_buf >= self.max_episode_length
```
3. 在BMPC的wrapper文件中，更改BMPCEnvWrapper类的step函数中dones的计算方式
```py
# dones = terminated | truncated
dones  = truncated
```
修改之后训练结果
```sh
train   E: 1            I: 300          R: -1744.0      T: 0:01:23   
train   E: 2            I: 450          R: -1865.4      T: 0:01:25   
train   E: 3            I: 600          R: -1712.6      T: 0:01:28   
train   E: 4            I: 750          R: -1920.8      T: 0:01:30   
train   E: 5            I: 900          R: -1729.6      T: 0:01:32 
```