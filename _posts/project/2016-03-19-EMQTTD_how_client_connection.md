---
layout: post
title: emqttd 之 client connection
description: tracking the connection of mqtt clinets
category: project
---

## client 和 connection 的建立












































emqttd_app:start_lisener(Protocol, Port, Opts) ->
    **MFArgs** = {emqttd_client, start_link, [emqttd:env(mqtt)]},
    %% note that MFArgs is passed as args
    esockd:open(Protocol, Port, merge_sockopts(Opts), **MFArgs**).
这里把emqttd_client:start_link([emqtd:env(Mqtt)])
这里的参数是emqttd里的mqtt协议配置，包括packet，session，client，queue.(参看emqttd.config文件)

esockd:open(Protocol, Port, Options, MFArgs) ->
    esockd_sup:start_listener(Protocol, Port, Options, **MFArgs**).

esockd_sup:start_listener(Protocol, Port, Options, MFArgs) ->
    MFA = {esockd_listener_sup, start_link,
           [Protocol, Port, Options, **MFArgs**]},
    ChildSpec = {child_id({Protocol, Port}), MFA,
                 transient, infinity, supervisor, [esockd_listener_sup]},
    %% cong sock4: start esockd_listener_sup under esockd_sup
    supervisor:start_child(?MODULE, ChildSpec).

esockd_lisener_sup:start_link(Protocol, Port, Options, **MFArgs**) ->
    ... ...
    %% cong sock6: start esockd_connection_sup, esockd_acceptor_sup, and esockd_listener
    %% jump to their start_link
    {ok, Sup} = supervisor:start_link(?MODULE, []),
    {ok, ConnSup} = supervisor:start_child(Sup,
                                           {connection_sup,
                                            {esockd_connection_sup, start_link, [Options, **MFArgs**, Logger]},
                                            transient, infinity, supervisor, [esockd_connection_sup]}),
    AcceptStatsFun = esockd_server:stats_fun({Protocol, Port}, accepted), % 定义一个处理状态的函数
    BufferTuneFun = buffer_tune_fun(proplists:get_value(buffer, Options),
                                    proplists:get_value(tune_buffer, Options, false)),
    {ok, AcceptorSup} = supervisor:start_child(Sup,
                                               {acceptor_sup,
                                                {esockd_acceptor_sup, start_link, [ConnSup, AcceptStatsFun, BufferTuneFun, Logger]},
                                                transient, infinity, supervisor, [esockd_acceptor_sup]}),
    {ok, _Listener} = supervisor:start_child(Sup,
                                             {listener,
                                              {esockd_listener, start_link, [Protocol, Port, Options, AcceptorSup, Logger]},
                                              transient, 16#ffffffff, worker, [esockd_listener]}),
    {ok, Sup}.
上面这一步确定了启动了三个child。三者之间的关系可以通过画的图来理解。


esockd_connection_sup:start_link(Options, **MFArgs**, Logger) ->
    gen_server:start_link(?MODULE, [Options, **MFArgs**, Logger], []).

esockd_connection_sup:init([Options, **MFArgs**, Logger]) ->
    process_flag(trap_exit, true),
    Shutdown    = proplists:get_value(shutdown, Options, brutal_kill),
    MaxClients  = proplists:get_value(max_clients, Options, ?MAX_CLIENTS),
    ConnOpts    = proplists:get_value(connopts, Options, []),
    RawRules    = proplists:get_value(access, Options, [{allow, all}]),
    AccessRules = [esockd_access:compile(Rule) || Rule <- RawRules],
    {ok, **#state**{max_clients  = MaxClients,
                conn_opts    = ConnOpts,
                access_rules = AccessRules,
                shutdown     = Shutdown,
                mfargs       = **MFArgs**,
                logger       = Logger}}.
                
到此为止，我们启动了connection的监控树，他其实是一个gen_server,这个服务器会等待接受的信号来触发。                
下面这一步是怎么触发的呢？我们先把这一步列出来，知道接下来的一步是怎么执行的。
esockd_connection_sup:handle_call({start_connection, Sock, SockFun}, _From,
            State = #state{conn_opts = ConnOpts, mfargs = **MFArgs**,
                           curr_clients = Count, access_rules = Rules}) ->
    case inet:peername(Sock) of
        {ok, {Addr, _Port}} ->
            case allowed(Addr, Rules) of
                true ->
                    Conn = esockd_connection:new(Sock, SockFun, ConnOpts), %% 这里其实只是尽心connection的配置，真正是通过下面的start_link来启动的。 
                    case catch **Conn:start_link**(**MFArgs**) of %% 这一步执行esockd_connection:start_link，进而执行 emqttd_client:start_link返回 {ok, ClientId} 
                        {ok, Pid} when is_pid(Pid) ->  %% 这里的Pid就是ClientId
                            put(Pid, true),
                            {reply, {ok, Pid, Conn}, State#state{curr_clients = Count+1}};%% 给esockd_connnection服务器返回{ok, ClientId, Conn}
                        ignore ->
                            {reply, ignore, State};
                        {error, Reason} ->
                            {reply, {error, Reason}, State};
                        What ->
                            {reply, {error, What}, State}
                    end;
                false ->
                    {reply, {error, fobidden}, State}
            end;
        {error, Reason} ->
            {reply, {error, Reason}, State}
    end;

esockd_connection:start_link(**{M, F, Args}**, Conn = ?CONN_MOD)
    when is_atom(M), is_atom(F), is_list(Args) ->
    erlang:apply(M, F, [Conn|Args]).

到此才执行emqttd_client:start_link:
start_link(Connection, MqttEnv) ->              % 被emqttd_app.erl里面启动的时候调用。proc_lib用于异步产生连接
    {ok, proc_lib:spawn_link(?MODULE, init, [[Connection, MqttEnv]])}.

在esockd_acceptor中启动了acceptor之后，当有客户端连接之后，发送{inet_async, LSock, Ref, {ok, Sock}}触发执行 handle_info，执行 esockd_connection_sup:start_connection 创建tcp连接：
`````````
start_connection(Sup, Mod, Sock, SockFun) ->
    case call(Sup, {start_connection, Sock, SockFun}) of %% 返回了{ok, ClientId, Connection} 
        {ok, Pid, Conn} ->
            % transfer controlling from acceptor to connection
            Mod:controlling_process(Sock, Pid), %% 将sock的控制权交给Pid（这里就是我们的ClientId）
            Conn:go(Pid),    %% 向Pid发送{go, Conn},表示socket已经准备好了。
            {ok, Pid};
        {error, Error} ->
            {error, Error}
    end.

`````````
这个函数的执行使用call函数，于是触发esockd_connection_sup的服务器，接着调用handle_call({start_connection, Sock, SockFun})，这里才是真正的启动connnection，也就是我们上面的esockd_connection_sup:handle_call函数。
在这里也就把我们之前关心的 emqttd_client 的启动放在参数里面，顺着前面已经梳理的思路启动了emqttd_client。现在我们重新来看看
这个handle_info函数。
在这里会判断当前的client连接数是否超过最大的客户端设置，如果超过了，那就会报错，提示maxlimit。否则就接着新建一个connection,完了将这个connection带到emqttd_client:start_link的参数中执行。

执行完
start_link(Connection, MqttEnv) ->              % 被emqttd_app.erl里面启动的时候调用。proc_lib用于异步产生连接
    {ok, proc_lib:spawn_link(?MODULE, init, [[Connection, MqttEnv]])}.
之后执行给模块的init函数，proc_lib:spawn_link完成之后，返回{ok, Pid}, handle_info 将这个信息写到进程字典中，并在状态中客户端计数处+1， 给gen_server返回消息{ok, Pid, Conn}；

当启动完成之后，利用Mod:controlling_process(Sock, Pid)将进程的控制权交个Pid，这样的话将相当于Sock接受的信息，就相当于我们的Pid进程接受到的消息，并进行相应的作用。接下来我们看下面client中的init函数：

emqttd_client中执行init：
``````````````
init([OriginConn, MqttEnv]) ->
    {ok, Connection} = OriginConn:**wait**(),
    {PeerHost, PeerPort, PeerName} =
    case Connection:peername() of
        {ok, Peer = {Host, Port}} ->
            {Host, Port, Peer};
        {error, enotconn} ->
            Connection:fast_close(),
            exit(normal);
        {error, Reason} ->
            Connection:fast_close(),
            exit({shutdown, Reason})
    end,
    ConnName = esockd_net:format(PeerName),
    SendFun = fun(Data) ->
        try Connection:async_send(Data) of
            true -> ok
        catch
            error:Error -> exit({shutdown, Error})
        end
    end,
    PktOpts = proplists:get_value(packet, MqttEnv),
    ParserFun = emqttd_parser:new(PktOpts),
    ProtoState = emqttd_protocol:init(PeerName, SendFun, PktOpts),
    RateLimit = proplists:get_value(rate_limit, Connection:opts()),
    State = run_socket(#client_state{connection   = Connection,
                                     connname     = ConnName,
                                     peername     = PeerName,
                                     peerhost     = PeerHost,
                                     peerport     = PeerPort,
                                     await_recv   = false,
                                     conn_state   = running,
                                     rate_limit   = RateLimit,
                                     parser_fun   = ParserFun,
                                     proto_state  = ProtoState,
                                     packet_opts  = PktOpts}),
    ClientOpts = proplists:get_value(client, MqttEnv),
    IdleTimout = proplists:get_value(idle_timeout, ClientOpts, 10),
    %% 监听client的各种请求
    gen_server:enter_loop(?MODULE, [], State, timer:seconds(IdleTimout)).

``````````````
首先，这里调用esockd_connection:wait()函数，这个函数会接收前面由go函数发送的{go, Conn}信息，
并更新connection，最后返回{ok, NewSock}，即init函数中的{ok, Connection}。
这个 client 也是一个gen_server ，到此为止，他就会监听消息，触发相应的动作了。

再看run_socket函数，这个函数规定了socket的一些状态。

    conn_state = blocked

    awaite_recv = true, 此时说明正在进行接收数据的状态，新数据来了需要等待。

    当 client_state{connection = Connection} 的时候，说明socket处于连接状态，这时候可以通过Connection:async_recv来接受socket的数据，在接受数据的时候，连接状态将置 await_recv = true 。

## listen 和 acceptor 到与上面进行控制权的转交

上面我们追踪了 client 和connection 的建立，并最终确立了 client_id, 在start_connection 时进行了控制权的转交，现在我们来看看转交之前的过程。
这要从哪里开始说起呢？当然要从esockd的启动开始：

````````````
esockd_app:start(_StartType, _StartArgs) ->
    esockd_sup:start_link().                    % jump to start esock_sup

````````````
接下来启动esockd_sup:start_link启动esockd_sup，并在init中定义了child的启动方式：esockd_server:start_link，在回调init中首先建立一个状态ets表，用来保存连接状态的性能指标。

这样后面接着就是前面使用esockd:open调用esockd_sup:start_listener 了，这就转到了上面的状态了。

## 总结

1 上面梳理了客户端通过 esockd 连接的整个过程。acceptor通过 controlling_process 函数将控制权交给了 connection，也就是 clientId。那么凡是 acceptor 监听到的信息就会把控制权转交给 clientPid 了。

2 client 在启动的时候，init 函数里面的 run_socket 时候，会通过检测 #client_state 里面的一些状态量来开启连接的相应状态，如果 client_state 里的  connection=Connection，那就说明此时可以进行数据的接收。该函数在这个时候开启了接收状态，即 Connection:async_recv(0, infinity)，这样就会调用 esockd_connection 里面的函数进行接收了。

