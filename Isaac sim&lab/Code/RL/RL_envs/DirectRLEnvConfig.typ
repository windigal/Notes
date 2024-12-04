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
首次创建日期：2024-11-28

*文件路径 `IsaacLab/source/extensions/omni.isaac.lab/omni/isaac/lab/envs/direct_rl_env_cfg.py` 直接式RL环境的配置类*

= *general settings*
- ```python seed：int```  种子
- ```python decimation：int```  策略控制步长除以模拟仿真步长，#text(blue)[类似action repeat？]
- ```python is_finite_horizon：bool```  是否限制episode长度，True为限制
- ```python episode_length_s：float```  以秒计算的episode长度。episode总长度计算公式为```python episode_length_steps = ceil(episode_length_s / (decimation_rate * physics_time_step))```
= *environment settings*
- ```python observation_space：SpaceType```  观测空间，类型可选择```python TypeVar("SpaceType", gym.spaces.Space, int, set, tuple, list, dict)```
- ```python observation_noise_model: NoiseModelCfg```  观测加噪模型
- ```python action_space：SpaceType```  动作空间
- ```python action_noise_model: NoiseModelCfg```  动作加噪模型