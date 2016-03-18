---
layout: post
title: git submodule 使用-主要是更新 
description: git submodule 的坑 
category: blog
---
    在使用git submodule的时候，遇到了下面的一些问题。
    1. 删除子模块：
    a）git rm --cached name_of_submodule  在主模块目录下面执行
    b）删除配置信息：
    vim .gitmodule 删除相应的模块信息
    vim .git/config 删除相应的模块信息
    c）删除相应的文件
    
    2. 子模块更新
    首先进入到子模块的目录，切换到master下面，执行git add , git commit , git push.
    然后回到主目录，执行git add, git commit, git push.
    现在我们的主模块使用的就是新的子模块了。
    查看子模块信息：git submodule status.


[congleetea]:    http://congleetea.github.io  "congleetea"
