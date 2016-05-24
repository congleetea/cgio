---
layout: post
title: emqttd 之 message stream 
description: tracking the message stream 
category: project
---

## 预备

在上一节中追踪了连接的连接和客户端的建立过程。当程序启动之后，esockd作为依赖项被启动，首先启动了esockd_sup，并指定了child，即esockd_listener_sup的启动方式。emqttd作为app启动，在启动 listeners 的时候将 emqttd_client:start_link 作为参数利用esockd:open打开socket开始一步步启动socket连接。待socket准备好之后，通过monitoring_process将控制权转到clientid一侧，向clientid发送一个{go, Conn}，于是connection进入监听状态。

接下来我们就来追踪信息流的走向，这是emqttd里一块比较大的内容。

在上一节中我们注意到了在client的init函数中对emqttd_protocol:init进行了初始化，我们重新看看这段代码:

```````````
    ProtoState = emqttd_protocol:init(PeerName, SendFun, PktOpts),

```````````
该函数定义：
````````````
%% @doc Init protocol
init(Peername, SendFun, Opts) ->
    MaxLen = get_value(max_clientid_len, Opts, ?MAX_CLIENTID_LEN),
    WsInitialHeaders = get_value(ws_initial_headers, Opts),
    #proto_state{peername           = Peername,
                 sendfun            = SendFun,
                 max_clientid_len   = MaxLen,
                 client_pid         = self(),
                 ws_initial_headers = WsInitialHeaders}.

````````````
在这段代码中，只是从各个参数中提取相关信息返回了 #proto_state{}，注意client_id的定义：client_id = self(), 我们在 emqttd_protocol:init 函数中输出self()，也就是上面的client_id 在 esockd_connection:go 中输出 Pid，这里的Pid就是 controlling_process 中转交控制权的Pid，我们发现他们都是一个，也就是说我们确定控制权最终是转交到了emqttd_client启动的进程中了。

client 在启动的时候，在 init 函数里面的 run_socket 里面，会通过检测 #client_state 里面的一些状态量来开启连接的相应状态，如果 client_state 里的  connection=Connection，那就说明此时可以进行数据的接收。该函数在这个时候开启了接收状态，即 Connection:async_recv(0, infinity)，这样就会调用 esockd_connection 里面的函数进行接收了。同时，在sendfun中定义了发送数据的函数。这样接收和发送都定义好了。

## 信息流的走向

上面我们看到了 Connec:async_recv 开启了recv的状态，那给服务器就进入了监听状态。

`````````````
handle_info({inet_async, _Sock, _Ref, {ok, Data}}, State) ->
    lager:error("~p ~p: handle_info: inet_async: ~p, ~p~n", [?MODULE, ?LINE, self(), Data]),
    Size = size(Data),
    ?LOG(debug, "RECV ~p", [Data], State),
    emqttd_metrics:inc('bytes/received', Size),
    received(Data, rate_limit(Size, State#client_state{await_recv = false}));

`````````````

在received中：

``````````````
rate_limit(_Size, State = #client_state{rate_limit = undefined}) ->
    run_socket(State);
rate_limit(Size, State = #client_state{rate_limit = Rl}) ->
    case Rl:check(Size) of
        {0, Rl1} ->
            run_socket(State#client_state{conn_state = running, rate_limit = Rl1});
        {Pause, Rl1} ->
            ?LOG(error, "Rate limiter pause for ~p", [Pause], State),
            erlang:send_after(Pause, self(), activate_sock),
            State#client_state{conn_state = blocked, rate_limit = Rl1}
    end.

``````````````

在received中会对数据包进行流控判断：
这里使用的是erlang里面的适配器变量的概念。适配器变量根据不同的情况在一个模块中进行不同的定义，封装出相应的接口，在使用的时候我们可以根据我们的需要选择我们需要的模块，当需要修改的时候，只需要改变适配器变量相关的代码，而使用的代码则不必改变太多。

# publish
