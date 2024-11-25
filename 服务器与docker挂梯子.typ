#import "./utils/template.typ": *
#import "./utils/diagbox.typ": *
#set par(justify: true,first-line-indent: 2em)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)
#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
)
参考文档：#link("https://wty-yy.xyz/posts/60686/")

= *服务器挂载梯子*

目前已在10.184.17.132服务器上安装了梯子，可以通过以下方式挂载：
```bash 
~/Clash/clash -d . 
```
打开新的终端，输入
```bash
proxy_on
```
测试是否成功挂载梯子
```bash
wget https://www.google.com
```

= *docker挂载梯子*
首先根据上述方法在服务器中挂载梯子，然后运行docker时加入以下参数：
```bash
--network=host
```
打开新的终端，输入
```bash
proxy_on
```
注意梯子与终端绑定