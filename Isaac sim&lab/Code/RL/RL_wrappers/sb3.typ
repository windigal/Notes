#import "../../../../utils/template.typ": *
#import "../../../../utils/diagbox.typ": *
#import "@preview/cuti:0.2.1": show-cn-fakebold
#show: show-cn-fakebold
#set par(justify: true)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)

首次创建日期：2024-11-25

*文件路径 `IsaacLab/source/extensions/omni.isaac.lab_tasks/omni/isaac/lab_tasks/utils/wrappers/sb3.py` 是一个Stable-Baselines3的训练包装器，用于训练已有环境。*

= *```python def process_sb3_cfg(cfg: dict) -> dict```*
功能：Convert simple YAML types to Stable-Baselines classes/components.
```python
Args
- cfg: dict #配置字典
Returns
- update_dict(cfg):dict #处理后的配置字典
```
处理Stable-Baselines3的配置字典，内部定义递归处理函数
\
```python def update_dict(hyperparams: dict[str, Any]) -> dict[str, Any]```

功能：计算所有表达式，提取字符串value中的值，统一转化为float类型

= *```python class Sb3VecEnvWrapper(VecEnv)```*
功能：Wraps around Isaac Lab environment for Stable Baselines3.

注意
- 当原始环境动作空间无上下界时，限制在-100\~100之间
```python 
if isinstance(action_space, gym.spaces.Box) and not action_space.is_bounded("both"):
    action_space = gym.spaces.Box(low=-100, high=100, shape=action_space.shape)
```

- 添加buffer用于记录episode的奖励与长度
```python
self._ep_rew_buf = torch.zeros(self.num_envs, device=self.sim_device)
self._ep_len_buf = torch.zeros(self.num_envs, device=self.sim_device)
```

- step函数分为```python def step_async(self, actions)```与```python def step_wait(self)```两部分
  - ```python def step_async(self, actions)``` 将输入转为numpy
  - ```python def step_wait(self)``` 与环境交互,处理数据并返回四元组```python obs, rew, dones, infos```
