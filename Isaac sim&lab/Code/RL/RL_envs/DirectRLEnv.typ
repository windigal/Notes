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
首次创建日期：2024-11-30

*文件路径 `IsaacLab/source/extensions/omni.isaac.lab/omni/isaac/lab/envs/direct_rl_env.py` 直接式RL环境类*

= *```python def step(self, action: torch.Tensor) -> VecEnvStepReturn```*
该函数实现RL环境与仿真环境的步进，获取下一个状态观测与奖励。该函数依次进行以下操作：
1. 对传入的动作进行加噪与预处理
```py
action = action.to(self.device)
# add action noise
if self.cfg.action_noise_model:
    action = self._action_noise_model.apply(action)
# process actions
self._pre_physics_step(action)
```
2. 进行物理仿真步进
```py
for _ in range(self.cfg.decimation):
    self._sim_step_counter += 1
    # set actions into buffers
    self._apply_action()
    # set actions into simulator
    self.scene.write_data_to_sim()
    # simulate
    self.sim.step(render=False)
    if self._sim_step_counter % self.cfg.sim.render_interval == 0 and is_rendering:
        self.sim.render()
    # update buffers at sim dt
    self.scene.update(dt=self.physics_dt)
```
3. 计算奖励与done，reset已经完成或者被中断的环境
```py
self.reset_terminated[:], self.reset_time_outs[:] = self._get_dones()
self.reset_buf = self.reset_terminated | self.reset_time_outs
self.reward_buf = self._get_rewards()
# -- reset envs that terminated/timed-out and log the episode information
reset_env_ids = self.reset_buf.nonzero(as_tuple=False).squeeze(-1)
if len(reset_env_ids) > 0:
    self._reset_idx(reset_env_ids)
    # if sensors are added to the scene, make sure we render to reflect changes in reset
    if self.sim.has_rtx_sensors() and self.cfg.rerender_on_reset:
        self.sim.render()
```
4. 获取下一步观测，如有加噪模型则加噪
```py
self.obs_buf = self._get_observations()
if self.cfg.observation_noise_model:
    self.obs_buf["policy"] = self._observation_noise_model.apply(
      self.obs_buf["policy"])
```