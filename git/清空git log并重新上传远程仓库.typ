#import "../utils/template.typ": *
#import "../utils/diagbox.typ": *
#set par(justify: true,first-line-indent: 2em)
#set par(leading: 1.5em, justify: true,)
#set text(size: 12pt)
#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
)

首先在工作区准备好要上传的项目，删除.git目录
```bash
rm -rf .git
```
然后重新初始化Git仓库
```bash
git init
```
添加所有文件并进行初始提交
```bash
git add .
git commit -m "Initial commit"
```
注：如果想进行匿名提交，首先设置
```bash
git config user.name "Anonymous"
git config user.email "<>"
```
之后再进行commit等操作即可