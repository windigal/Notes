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
#align(center)[#text(size: 19pt, font: ("Times New Roman","SimHei"))[*取消环境terminal*]] 
#align(center)[#text(size: 14pt)[2024-12-01]]

由于Isaac sim环境存在terminal的情况，BMPC训练效果不佳。本文记录将环境更改为超时结束的方式。

注意：使用环境均为直接式的环境（`DirectRLEnv`），以`cartpole-direct-v0`为例

1. 在直接式环境类`DirectRLEnv`的`step`函数中，修改`reset_buf`为`reset.time_outs`，即不考虑环境中断导致的`reset`
```py
# self.reset_buf = self.reset_terminated | self.reset_time_outs
self.reset_buf = self.reset_time_outs
```
2. 在`Cartpole`环境类`CartpoleEnv`的函数`_get_dones`中，修改`time_out`（只是为了输出整齐）
```py
# time_out = self.episode_length_buf >= self.max_episode_length - 1
time_out = self.episode_length_buf >= self.max_episode_length
```
3. 在BMPC的`wrapper`文件中，更改`BMPCEnvWrapper`类的`step`函数中`dones`的计算方式
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