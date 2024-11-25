#import "./utils/template.typ": *
#import "./utils/diagbox.typ": *
#set par(justify: true,first-line-indent: 2em)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)
#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
)
参考文档：#link("https://docs.robotsfan.com/isaaclab/source/overview/reinforcement-learning/rl_existing_scripts.html")
\
*注意：第一次训练某个环境，需要挂梯子进行资产下载，之后训练则可以直连，挂梯子教程参考`./服务器与docker挂梯子.typ`*

= *使用Isaac Lab框架训练已有环境*
Isaac Lab目前继承了四种强化学习训练框架：RL-Games、RSL-RL、SKRL与Stable-Baselines3

== *Stable-Baselines3*
```bash
conda activat iassclab
python ~/IsaacLab/source/standalone/workflows/sb3/train.py --task Isaac-Cartpole-v0 --headless --device cpu
```