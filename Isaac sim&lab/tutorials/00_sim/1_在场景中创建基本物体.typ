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
#align(center)[#text(size: 19pt, font: "SimHei")[*在场景中创建基本物体*]#text(size: 19pt)[*#footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/00_sim/spawn_prims.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-07]]

本文记录如何在场景中创建基本场景元素和物体#footnote[IsaacLab/source/standalone/tutorials/00_sim/spawn_prims.py]。

= *生成地面平面*
`sim_utils`提供了许多资产的配置接口，对于地面平面，可以通过`GroundPlaneCfg`类进行配置
```py
cfg_ground = sim_utils.GroundPlaneCfg()
cfg_ground.func("/World/defaultGroundPlane", cfg_ground)
```
`func`函数用于将资产应用于场景中的指定位置
= *生成灯光*

可以添加许多种灯光，如远光灯、球形灯、圆盘灯和圆柱灯。下面通过`DistantLightCfg`类向场景中添加一个远光灯
```py
cfg_light_distant = sim_utils.DistantLightCfg(
        intensity=3000.0,
        color=(0.75, 0.75, 0.75),
    )
cfg_light_distant.func("/World/lightDistant", cfg_light_distant, translation=(1, 0, 10))
```
在计算机图形学中，translation是指物体的平移变换，即物体从一个位置移动到另一个位置。在这里，我们将远光灯从(0, 0, 0)移动到(1, 0, 10)。

= *生成基本形状*
1. 通过将不同的物体进行分组，称为一个Xform或者变换基本体，来进行更方便的管理
```py
prim_utils.create_prim("/World/Objects", "Xform")
```
2. 之后通过`ConeCfg`类向Xform中添加两个圆锥体
```py
cfg_cone = sim_utils.ConeCfg(radius=0.15,height=0.5,
    visual_material=sim_utils.PreviewSurfaceCfg(diffuse_color=(1.0, 0.0, 0.0)))
cfg_cone.func("/World/Objects/Cone1", cfg_cone, translation=(-1.0, 1.0, 1.0))
cfg_cone.func("/World/Objects/Cone2", cfg_cone, translation=(-1.0, -1.0, 1.0))
```
可以设置底面半径、高度，以及可视化材质的颜色等。

3. 还可以添加刚体物理属性，如质量、摩擦力和弹性等
```py
cfg_cone_rigid = sim_utils.ConeCfg(radius=0.15,height=0.5,
    rigid_props=sim_utils.RigidBodyPropertiesCfg(),
    mass_props=sim_utils.MassPropertiesCfg(mass=1.0),
    collision_props=sim_utils.CollisionPropertiesCfg(),
    visual_material=sim_utils.PreviewSurfaceCfg(diffuse_color=(0.0, 1.0, 0.0)))
cfg_cone_rigid.func(
    "/World/Objects/ConeRigid", cfg_cone_rigid, translation=(-0.2, 0.0, 2.0), orientation=(0.5, 0.0, 0.5, 0.0))
```
都可以通过`sim_utils`提供的类进行设置

4. 设置一个可形变的长方体
```py
cfg_cuboid_deformable = sim_utils.MeshCuboidCfg(
    size=(0.2, 0.5, 0.2),
    deformable_props=sim_utils.DeformableBodyPropertiesCfg(),
    visual_material=sim_utils.PreviewSurfaceCfg(diffuse_color=(0.0, 0.0, 1.0)),
    physics_material=sim_utils.DeformableBodyMaterialCfg())
cfg_cuboid_deformable.func("/World/Objects/CuboidDeformable",                   
                           cfg_cuboid_deformable, 
                           translation=(0.15, 0.0, 2.0))
```
可形变物体需要添加一个可形变物理属性的网格对象，且仅支持在GPU模拟中支持。

= *从其他文件中添加物体*
可以从USD、URDF或OBJ文件等文件中导入物体，以下从USD文件中导入一个网格
```py
cfg = sim_utils.UsdFileCfg(usd_path=f"{ISAAC_NUCLEUS_DIR}/Props/Mounts/    SeattleLabTable/table_instanceable.usd")
cfg.func("/World/Objects/Table", cfg, translation=(0.0, 0.0, 1.05))
```

= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/00_sim/spawn_prims.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。