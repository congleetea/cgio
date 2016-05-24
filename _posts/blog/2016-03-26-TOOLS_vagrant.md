---
layout: post
title: tools 之 vagrant 使用 
description: 使用vagrant来建立虚拟机 
category: blog
---

## 0 安装 virtualbox 和 vagrant 
    
上官网下载最新的安装即可。
还要下载你需要的box，也就是你需要的系统镜像。

可以直接通过：
    vagrant box add ubuntu14.04_amd64 xxx.box 
这样就会产生~/.vagrant.d文件夹，并把xxx.box解压之后放在boxes文件夹中。

## 1 创建一个目录来管理所有的虚拟机：
$ mkdir vagrant && cd vagrant  
在该目录下面创建一个针对某个主机的文件:
$ mkdir machines 
在该目录下面执行：
$ vagrant init ubuntu14.04_amd64 # 后者就是box的名字，如果不指出，默认是base
这样就在该目录下面产生Vagrantfile文件了。

## 2 配置Vagrantfile

这是重点，根据你自己的需要来设计虚拟机。

## 快速操作

## 1 步骤

1 在你的目录下面新建一个vagrant目录， 在里面执行：

$ vagrant box add

完成之后会在产生~/.vagrant.d文件，查看里面的文件：

$ ls
boxes  data  gems  insecure_private_key  rgloader  setup_version  tmp

接着把下载的镜像解压，出现boxes文件，用它把.vagrant.d里面的boxes替换掉。

2 在vagrant目录里面建立一个属于这个box的文件夹：

$ mkdir mongodbTrusty && cd mongodbTrusty

3 如果你已经有了vagrangfile，那么直接 将vagrantfile复制到该目录下面，修改ip为你需要的ip地址。执行： 

$ vagrant up 

等执行结束就安装好了。
 
如果没有的话，执行vagrant init会生成一个，你修改里面的配置，重新执行vagrant up就行了。

4 登陆到这台机器上：
$ vagrant ssh 
如果有多台机器，跟上主机名和ip。
