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
首次创建日期：2024-12-07

参考文档：#link("https://docs.robotsfan.com/isaaclab/source/tutorials/01_assets/run_rigid_object.html")

*文件路径 `IsaacLab/source/standalone/tutorials/01_assets/run_rigid_object.py` *


= *设置场景*
创建一个圆锥体刚性物体，此时不使用`ConeCfg`类进行创建，而使用` assets.RigidObjectCfg`类进行封装。该类可以按照某一些生成规则批量生成一些资产
```py
origins = [[0.25, 0.25, 0.0], [-0.25, 0.25, 0.0], [0.25, -0.25, 0.0], [-0.25, -0.25, 0.0]]
for i, origin in enumerate(origins):
    prim_utils.create_prim(f"/World/Origin{i}", "Xform", translation=origin)

# Rigid Object
cone_cfg = RigidObjectCfg(
    prim_path="/World/Origin.*/Cone",
    spawn=sim_utils.ConeCfg(
        radius=0.1,
        height=0.2,
        rigid_props=sim_utils.RigidBodyPropertiesCfg(),
        mass_props=sim_utils.MassPropertiesCfg(mass=1.0),
        collision_props=sim_utils.CollisionPropertiesCfg(),
        visual_material=sim_utils.PreviewSurfaceCfg(diffuse_color=(0.0, 1.0, 0.0), metallic=0.2),),
    init_state=RigidObjectCfg.InitialStateCfg())
cone_object = RigidObject(cfg=cone_cfg)
```
通过正则表达式在每个位置生成刚性物体对象，将返回的实体包装如字典中传入主函数
```py
scene_entities = {"cone": cone_object}
return scene_entities, origins
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



= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/01_assets/run_rigid_object.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。