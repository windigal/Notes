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
#align(center)[#text(size: 19pt, font: "SimHei")[*创建空场景*]#text(size: 19pt)[*#footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/00_sim/create_empty.html]*]] 
#align(center)[#text(size: 14pt)[2024-12-07]]
本文记录如何在Isaac Sim中创建一个空场景#footnote[IsaacLab/source/standalone/tutorials/00_sim/create_empty.py]。

= *启动模拟器*
1. 首先创建一个命令行参数解析器，解析用户提供的参数
```py
parser = argparse.ArgumentParser(description="Tutorial on creating an empty stage.")
```

2. 将AppLauncher的参数添加到解析器中，包括`--headless`，`--livestream`，`--device`，`--enable_cameras`， `experience`，`kit_args`
```py
AppLauncher.add_app_launcher_args(parser)
```
3. 解析命令行参数
```py
args_cli = parser.parse_args()
```

4. 创建AppLauncher对象，传入命令行参数，获取模拟器对象
```py
app_launcher = AppLauncher(args_cli)
simulation_app = app_launcher.app
```

= *配置模拟上下文*

从Python脚本中启动的模拟器，用户可以完全控制模拟器的行为。所有这些操作都通过模拟上下文处理。其中，`SimulationCfg`类用于配置模拟器的参数，`SimulationContext`类用于管理模拟器的状态。
```py
# Initialize the simulation context
sim_cfg = SimulationCfg(dt=0.01)
sim = SimulationContext(sim_cfg)
# Set main camera
sim.set_camera_view([2.5, 2.5, 2.5], [0.0, 0.0, 0.0])
```

= *模拟器reset与step*
可以通过直接调用`SimulationContext`类实例的相关方法进行控制
```py
sim.reset()
print("[INFO]: Setup complete...")
while simulation_app.is_running():
    sim.step()
```
最后，通过调用```py simulation_app.close()```方法关闭模拟器

= *可视化*
有两种调用GUI的方法。如果在有Windows环境或者有显示器的Linux环境下，可以直接运行
```sh
python ~/IsaacLab/source/standalone/tutorials/00_sim/create_empty.py
```
在无显示器的Linux环境下，例如服务器或者docker中，可以通过添加`--headless`参数运行，或者设置流式传输`--livestream`，在另一台有显示器的机器上通过Omniverse Streaming Client进行进行串流查看。
```sh
python ~/IsaacLab/source/standalone/tutorials/00_sim/create_empty.py --livestream 1
```
注意：如果设置`--livestream 1`或者`--livestream 2`，则自动启用`--headless`模式。