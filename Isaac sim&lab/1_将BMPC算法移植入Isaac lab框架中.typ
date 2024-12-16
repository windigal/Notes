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
#align(center)[#text(size: 19pt, font: ("Times New Roman","SimHei"))[*将BMPC算法移植如Isaac Lab框架中*]#text(size: 19pt)[*#footnote[https://docs.robotsfan.com/isaaclab/source/tutorials/02_scene/create_scene.html]*]] 
#align(center)[#text(size: 14pt)[2024-11-28]]

历时4天将BMPC算法移植入Isaac lab框架中，下面讲一下移植过程。
= *将BMPC算法使用pip安装为库*
在BMPC文件路径下创建一个setup.py文件，内容如下：
```python
from setuptools import find_packages, setup

core_requirements = [
    "glfw==2.6.4",
    "hydra-submitit-launcher==1.2.0",
    "kornia==0.7.1",
    "open3d==0.18.0",
    "opencv-contrib-python==4.9.0.80",
    "sapien==2.2.1",
    "submitit==1.5.1",
    "patchelf==0.17.2.1",
    "pyquaternion==0.9.9",
    "transforms3d==0.4.1",
]
setup(
    name="bmpc",
    version="0.1",
    author="Xian JiaoTong University",
    url="https://github.com/bmpc-anonymous/bmpc",
    description="BMPC Algorithm",
    packages=find_packages(),
    include_package_data=True,
    python_requires=">3.8",
    install_requires=core_requirements,
)
```
然后在BMPC文件路径下运行命令：
```shell
pip install -e .
```
安装完成后，需要继续下载torchrl-nightly库，运行命令：
```shell
pip install torchrl-nightly==2024.7.3 --no-deps
```
注意：torchrl-nightly安装时不要安装依赖，否则会自动下载新版torch

= *编写BMPC的wrapper*
编写过程基本参考sb3在Isaac Lab中的wrapper，主要有以下不同
- 删除process_sb3_cfg函数，BMPC库中有相应的config处理函数
- 在```python __init__```函数中，将动作与观测空间记为属性，并将动作限制在[-1, 1]之间
- 将sb3的step_async与step_wait函数合并为step函数

= *编写BMPC的train文件*
该文件在BMPC库中train文件的基础上进行修改，主要改动点如下
- 在前面加入启动Isaac Sim的代码，复制自sb3训练文件
- hydra依然使用hydra.main装饰器，因此算法config就在该层文件夹中
- 将原先的make_env中的内容移到train中，#text(red)[其中env的config调用直接实例化了对应的环境类，之后还需要改进]

= *其他文件修改*
由于BMPC目前不支持并行环境，故很多tensor的传递需要进行维度变化，并进行其他数据传输对齐。主要改动点如下
- ``` bmpc\envs\wrappers\tensor.py ```文件中，注释掉step函数中info的处理
- bmpc在Isaac Lab中的wrapper中，将step函数传入的actions最开始加入一个维度，以适应底层环境的输入格式
- ``` bmpc\trainer\online_trainer.py ```文件中，在to_td函数中最后reward的处理，保证加入的形状为(1,)