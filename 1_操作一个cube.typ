#import "./utils/template.typ": *
#import "./utils/diagbox.typ": *
#set par(justify: true,first-line-indent: 2em)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)
= *添加cube*

点击上方Create, 在shape中选择cube, 即可添加一个cube到场景原点中。

= *移动与更改cube*

选中cube，可以沿着x,y,z轴移动cube，也可以通过左侧工具栏切换模式。
按W为move模式，E为rotate模式，R为scale模式。当Move中心为灰色时为全局坐标系下，橙色时为局部坐标系下。也可以在Property中更改cube的位置，旋转角度，大小等。

= *视角*

点击上方Windows，Viewpoint，可以同时开双视角。多个物体同时存在时，选中其中一个按F，可以聚焦到该物体。

= *物体分组*

在右侧Stage中，可以添加Xform，将多个物体放入其中则共享同一个全局坐标系，同时进行一些操作。