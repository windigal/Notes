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
#align(center)[#text(size: 19pt, font: "SimHei")[*使用交互式场景*]#text(size: 19pt)[*#footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/02_scene/create_scene.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-12]]
本文记录如何使用交互式场景创建Cartpole场景的过程#footnote[IsaacLab/source/standalone/tutorials/02_scene/create_scene.py]。

= *设置场景*
将cartpole场景设置集中到一个CartpoleSceneCfg类中，该类继承自scene.InteractiveSceneCfg，其中不可交互的光源和地面使用assets.AssetBaseCfg类进行配置，而可交互的物体使用assets.ArticulationCfg类进行配置
```py
@configclass
class CartpoleSceneCfg(InteractiveSceneCfg):
    ground = AssetBaseCfg(prim_path="/World/defaultGroundPlane", 
                          spawn=sim_utils.GroundPlaneCfg())
    dome_light = AssetBaseCfg(prim_path="/World/Light", 
                              spawn=sim_utils.DomeLightCfg(intensity=3000.0, 
                              color=(0.75, 0.75, 0.75)))
    cartpole: ArticulationCfg = CARTPOLE_CFG.replace(
                                prim_path="{ENV_REGEX_NS}/Robot")
```
地面平面和光源使用绝对路径来指定，而cartpole使用相对路径来指定。相对路径使用 `ENV_REGEX_NS` 变量来进行指定，这是一个特殊的变量，在场景创建期间会被环境名称替换。任何带有 `ENV_REGEX_NS` 变量的实体的prim路径在每个环境中都会被克隆。这个路径会被场景对象替换为 `/World/envs/env_{i}` ，其中`i`是环境索引。

= *场景实例化*
首先实例化一个CartpoleSceneCfg对象，传入`num_envs`与`env_spacing`参数，之后将实例传入scene.InteractiveScene类进行实例化
```py
scene_cfg = CartpoleSceneCfg(num_envs=args_cli.num_envs, env_spacing=2.0)
scene = InteractiveScene(scene_cfg)
```

= *模拟循环*
场景中的元素可以类似字典的索引方式进行获取
```py
robot = scene["cartpole"]
```
其他操作与assets.Articulation类接口类似

= *可视化*
```sh
python ~/IsaacLab/source/standalone/tutorials/02_scene/create_scene.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。
#figure(image("imgs/set_scene.gif", width: 100%), numbering: none)