---
layout: post
title: erlang 之 start process
description: methods of erlang start process 
category: blog 
---

### receive ...
receive 其实是一个同步的阻断式操作, 只有接受到消息或者接受超时才会继续后面的操作.
erlang中很多等待的动作都会通过它来完成.

receive 
    Pattern1 -> do_1();
    ...;
    Patternn -> do_n()
after
    ExprT -> do_if_timeout_millseconds()
end.
        

### gen_server的启动
在官方文档中,对gen_server的启动是这样描述的:

The gen_server process calls Module:init/1 to initialize. To ensure a synchronized start-up procedure, start_link/3,4 does  not  return until Module:init/1 has returned.

这就是说gen_server的启动(start,start_link)是同步的, 只有当执行完init回调函数之后才会返回start或者start_link的值, 在启动的时候会调用sync_await等待回调的返回结果,这是一个同步过程.而其底层的实现也是通过使用proc_lib:start_link来创建一个进程并等待其启动完成的, 当进程启动完成之后会有一个发送响应消息的动作来结束当前的sync_await的等待.
这里我们可以看看proc_lib:start_link的启动代码:

------------
-spec start_link(Module, Function, Args) -> Ret when
      Module :: module(),
      Function :: atom(),
      Args :: [term()],
      Ret :: term() | {error, Reason :: term()}.

start_link(M, F, A) when is_atom(M), is_atom(F), is_list(A) ->
    start_link(M, F, A, infinity).

-spec start_link(Module, Function, Args, Time) -> Ret when
      Module :: module(),
      Function :: atom(),
      Args :: [term()],
      Time :: timeout(),
      Ret :: term() | {error, Reason :: term()}.

start_link(M, F, A, Timeout) when is_atom(M), is_atom(F), is_list(A) ->
    Pid = ?MODULE:spawn_link(M, F, A),         %% NOTE1 
    sync_wait(Pid, Timeout).                   %% NOTE2

-spec start_link(Module, Function, Args, Time, SpawnOpts) -> Ret when
      Module :: module(),
      Function :: atom(),
      Args :: [term()],
      Time :: timeout(),
      SpawnOpts :: [spawn_option()],
      Ret :: term() | {error, Reason :: term()}.

start_link(M,F,A,Timeout,SpawnOpts) when is_atom(M), is_atom(F), is_list(A) ->
    Pid = ?MODULE:spawn_opt(M, F, A, ensure_link(SpawnOpts)),
    sync_wait(Pid, Timeout).

sync_wait(Pid, Timeout) ->
    receive
	{ack, Pid, Return} ->
	    Return;
	{'EXIT', Pid, Reason} ->
	    {error, Reason}
    after Timeout ->
	    unlink(Pid),
	    exit(Pid, kill),
	    flush(Pid),
	    {error, timeout}
    end.
---------------
我们发现NOTE1,proc_lib:start_link 首先调用proc_lib:spawn_link 产生一个子进程, 然后进入NOTE2: sync_wait(Pid, Timeout). 
等待执行完回调init之后回复的响应. 然后才结束.
当然, 这里的 *proc_lib:spawn_link* 就是一个异步的, 立刻就返回一个子进程的pid了, 而不等待执行完回调之后才返回.

此外, 其实spawn*系列的函数也又是通过调用erlang:spawn*来实现的, 因此可以总结 spawn* 系列的函数其实都是异步的, 而start_*系列的函数则还要加上一个等待执行完回调返回的过程, 因此是同步的操作.
