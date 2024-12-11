#import "../../../utils/template.typ": *
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
首次创建日期：2024-12-09

参考文档：#link("https://docs.robotsfan.com/isaaclab/source/tutorials/01_assets/run_articulation.html")

*文件路径 `IsaacLab/source/standalone/tutorials/01_assets/run_articulation.py` *

本文件记录Cartpole的场景与模拟
= *Cartpole场景设计*
Cartpole由地面，光照，以及两个Cartpole系统组成
== *地面*
地面包含Looks，GroundPlane、Environment、SphereLight和physicsMaterial。其中Looks是地面的外观，GroundPlane为地面加入碰撞器检测，Environment是渲染地面网格，SphereLight是Cartpole顶部的球面光，physicsMaterial是地面的物理材质
#figure(image("imgs/GroundPlane.png"), caption: "GroundPlane")
== *光照*
全环境光照为穹顶光源，一种均匀扩散的光源
#figure(image("imgs/Light.png"), caption: "Light")

== *Cartpole系统*
Cartpole系统由两个相同的Xform组成，每个Xform包括slider、cart、pole。
此外有一个Fixed Joint放置在slider上，cart下有一个Revolute Joint连接pole。
#figure(image("imgs/Cartpole.png"), caption: "Cartpole")

= *资产配置*
通过USD文件导入，创建两个Cartpole系统，并导入地面和光照
```py
cfg = sim_utils.GroundPlaneCfg()
cfg.func("/World/defaultGroundPlane", cfg)
cfg = sim_utils.DomeLightCfg(intensity=3000.0, color=(0.75, 0.75, 0.75))
cfg.func("/World/Light", cfg)
origins = [[0.0, 0.0, 0.0], [-1.0, 0.0, 0.0]]
prim_utils.create_prim("/World/Origin1", "Xform", translation=origins[0])
prim_utils.create_prim("/World/Origin2", "Xform", translation=origins[1])
cartpole_cfg = CARTPOLE_CFG.copy()
cartpole_cfg.prim_path = "/World/Origin.*/Robot"
cartpole = Articulation(cfg=cartpole_cfg)
```
= *模拟循环*
该模拟每间隔250个模拟步进行一次初始化，每次初始化将锥体的位置随机分布在围绕某个原点的圆柱体内
```py
root_state = cone_object.data.default_root_state.clone()
root_state[:, :3] += origins
root_state[:, :3] += math_utils.sample_cylinder(
    radius=0.1, h_range=(0.25, 0.5), size=cone_object.num_instances, device=cone_object.device
)
cone_object.write_root_state_to_sim(root_state)
cone_object.reset()
```
可以将一些其他数据写入模拟缓冲区，本例子中暂时没有其他数据需要写入
```py
cone_object.write_data_to_sim()
```
更新物体对象的内部缓冲区，同步物体对象的状态（例如位置）
```py
cone_object.update(sim_dt)
```
随机采样关节力矩，并写入cartpole中，再写入PhysX缓冲区，更新缓冲区的状态
```py
efforts = torch.randn_like(robot.data.joint_pos) * 5.0
robot.set_joint_effort_target(efforts)
robot.write_data_to_sim()
sim.step()
count += 1
robot.update(sim_dt)
```


= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/01_assets/run_articulation.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。