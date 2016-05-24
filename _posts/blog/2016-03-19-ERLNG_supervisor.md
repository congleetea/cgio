---
layout: post
title: erlang 之 supervisor 
description: erlang 监控树 
category: blog 
---

supervisor里面有一个问题是：监控树下的child到底是什么时候启动的。我们首先看对 supervisor:start_link的解释:
----------
The  created  supervisor  process  calls Module:init/1 to find out about restart strategy, maximum restart intensity and
child processes. To ensure a synchronized start-up procedure, start_link/2,3 does not  return  until  Module:init/1  has
returned and all child processes have been started.
----------

也就是说被创建的supervisor 进程会调用 Module:init 查找重启策略，最大重启频率和子进程。为了却被同步启动步骤，start_link会
在init被执行完，并且所有的子进程都启动之后才返回。因此执行完init之后会启动子进程。
这也就是说子进程的一种启动方式是在supervisor:start_link调用init函数，如果init中定义了子进程的启动方式，那么子进程会在这
个时候被启动。
可以参考这里的例子： [supervisor](http://diaocow.iteye.com/blog/1762895)

我们注意到supervisor还有一个函数 supervisor:start_child，我们看一下这个函数： 

start_child(SupRef, ChildSpec) -> startchild_ret()
     Dynamically adds a child specification to the supervisor SupRef which starts the corresponding child process.
这是动态添加一个子进程到监控树 SupRef 下面。
