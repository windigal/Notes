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
#align(center)[#text(size: 19pt, font: "SimHei")[*可形变物体交互*]#text(size: 19pt)[*#footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/01_assets/run_deformable_object.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-11]]
本文记录可形变物体的模拟，需要在GPU上运行#footnote[IsaacLab/source/standalone/tutorials/01_assets/run_deformable_object.py]

= *资产配置*
通过`assets.DeformableObject`类导入可形变物体，创建四个立方体
```py
origins = [[0.25, 0.25, 0.0], [-0.25, 0.25, 0.0], [0.25, -0.25, 0.0], [-0.25, -0.25, 0.0]]
for i, origin in enumerate(origins):
    prim_utils.create_prim(f"/World/Origin{i}", "Xform", translation=origin)
cfg = DeformableObjectCfg(
    prim_path="/World/Origin.*/Cube",
    spawn=sim_utils.MeshCuboidCfg(size=(0.2, 0.2, 0.2),
      deformable_props=sim_utils.DeformableBodyPropertiesCfg(rest_offset=0.0,
                                 contact_offset=0.001),
      visual_material=sim_utils.PreviewSurfaceCfg(
                                diffuse_color=(0.5, 0.1, 0.0)),
      physics_material=sim_utils.DeformableBodyMaterialCfg(
                               poissons_ratio=0.4, 
                               youngs_modulus=1e5)),
      init_state=DeformableObjectCfg.InitialStateCfg(
                                     pos=(0.0, 0.0, 1.0)),
                                     debug_vis=True)
cube_object = DeformableObject(cfg=cfg)
```
= *模拟循环*
每隔250步，随机生成物体的位置和朝向，写入原来`nodal_state`并加入模拟缓冲区
```py
# reset the nodal state of the object
nodal_state = cube_object.data.default_nodal_state_w.clone()
# apply random pose to the object
pos_w = torch.rand(cube_object.num_instances, 3, 
                   device=sim.device) * 0.1 + origins
quat_w = math_utils.random_orientation(cube_object.num_instances, 
                                       device=sim.device)
nodal_state[..., :3] = cube_object.transform_nodal_pos(nodal_state[..., :3], pos_w, quat_w)
```
模拟的每一步，移动第0个和第3个立方体的z坐标，并将他们的网格中的一个顶点进行运动学约束，使其位置严格按照指定的目标位置，而其他网格顶点可受到物理力的影响

#text(blue)[`transform_nodal_pos`基于给定的位置`pos`和旋转四元数`quat`实现节点的平移和旋转，
```py
def transform_nodal_pos(
        self, nodal_pos: torch.tensor, pos: torch.Tensor | None = None, quat: torch.Tensor | None = None
    ) -> torch.Tensor:
        mean_nodal_pos = nodal_pos.mean(dim=1, keepdim=True)
        nodal_pos = nodal_pos - mean_nodal_pos
        return math_utils.transform_points(nodal_pos, pos, quat) + mean_nodal_pos
```
由于四元数本身只能绕世界坐标系的原点旋转，如果想绕物体的中心旋转，需要手动将物体平移到原点，完成旋转操作后再平移回原始位置。]
```py
# update the kinematic target for cubes at index 0 and 3
# we slightly move the cube in the z-direction by picking the vertex at index 0
nodal_kinematic_target[[0, 3], 0, 2] += 0.001
# set vertex at index 0 to be kinematically constrained
# 0: constrained, 1: free
nodal_kinematic_target[[0, 3], 0, 3] = 0.0
# write kinematic target to simulation
cube_object.write_nodal_kinematic_target_to_sim(nodal_kinematic_target)
cube_object.write_data_to_sim()
```
= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/01_assets/run_deformable_object.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。

#figure(image("imgs/deformable.gif", width: 100%), numbering: none)