---
layout: post
title: emqttd pressure test
description: record the configuration and some method to check
category: project 
---
参数的配置主要有emqttd的配置和系统的配置两部分。emqttd的配置主要是两个文件：etc/vm.args 和 etc/emqttd.config。系统配置主要是/etc/sysctl.config 和 etc/security/limit.config。 
    
## emqttd的配置：
1 /etc/vm.args 的配置
这是对erlang的虚拟机的参数设置。[https://github.com/emqtt/emqttd/wiki/etc-vm.args-for-benchmark](vm.args)

`````````````````````````````````````````````````````
## Name of the node
-name emqttd@127.0.0.1
## Cookie for distributed erlang
-setcookie emqttdsecretcookie

##-------------------------------------------------------------------------
## Flags
##-------------------------------------------------------------------------
## Heartbeat management; auto-restarts VM if it dies or becomes unresponsive
## (Disabled by default..use with caution!)
##-heart
-smp true
## Enable kernel poll and a few async threads
+K true
## 12 threads/core. our machine is 8 core
+A 96 
## max process numbers
+P 2097152
## Sets the maximum number of simultaneously existing ports for this system
+Q 1048576

## max atom number
## +t
##-------------------------------------------------------------------------
## Env
##-------------------------------------------------------------------------
## Increase number of concurrent ports/sockets
-env ERL_MAX_PORTS 1048576
-env ERTS_MAX_PORTS 1048576
-env ERL_MAX_ETS_TABLES 1024

## Tweak GC to run more often
-env ERL_FULLSWEEP_AFTER 1000

`````````````````````````````````````````````````````

2 /etc/emqttd.config的配置
这是对emqttd的配置。[https://github.com/emqtt/emqttd/wiki/etc-emqttd.config-for-benchmark](emqttd.config)
````````````````````````````````````````````````````````````````````
% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et
[{kernel,
    [{start_timer, true},
     {start_pg2, true}
 ]},
 {sasl, [
    {sasl_error_logger, {file, "log/emqttd_sasl.log"}}
 ]},
 {ssl, [
    %{versions, ['tlsv1.2', 'tlsv1.1']}
 ]},
 {lager, [
    {colored, true},
    {async_threshold, 5000},
    {error_logger_redirect, false},
    {crash_log, "log/emqttd_crash.log"},
    {handlers, [
        %%{lager_console_backend, info},
        {lager_file_backend, [
            {formatter_config, [time, " ", pid, " [",severity,"] ", message, "\n"]},
            {file, "log/emqttd_error.log"},
            {level, error},
            {size, 104857600},
            {date, "$D0"},
            {count, 30}
        ]}
    ]}
 ]},
 {esockd, [
    {logger, {lager, error}}
 ]},
 {emqttd, [
    %% Authentication and Authorization
    {access, [
        %% Authetication. Anonymous Default
        {auth, [
            %% Authentication with username, password
            %{username, []},
            %% Authentication with clientid
            %{clientid, [{password, no}, {file, "etc/clients.config"}]},

            %% Authentication with LDAP
            % {ldap, [
            %    {servers, ["localhost"]},
            %    {port, 389},
            %    {timeout, 30},
            %    {user_dn, "uid=$u,ou=People,dc=example,dc=com"},
            %    {ssl, fasle},
            %    {sslopts, [
            %        {"certfile", "ssl.crt"},
            %        {"keyfile", "ssl.key"}]}
            % ]},

            %% Allow all
            {anonymous, []}
        ]},
        %% ACL config
        {acl, [
            %% Internal ACL module
            {internal,  [{file, "etc/acl.config"}, {nomatch, allow}]}
        ]}
    ]},
    %% MQTT Protocol Options
    {mqtt, [
        %% Packet
        {packet, [
            %% Max ClientId Length Allowed
            {max_clientid_len, 1024},
            %% Max Packet Size Allowed, 64K default
            {max_packet_size,  65536}
        ]},
        %% Client
        {client, [
            %% Socket is connected, but no 'CONNECT' packet received
            {idle_timeout, 20} %% seconds
            %TODO: Network ingoing limit
            %{ingoing_rate_limit, '64KB/s'}
            %TODO: Reconnet control
        ]},
        %% Session
        {session, [
            %% Max number of QoS 1 and 2 messages that can be “in flight” at one time.
            %% 0 means no limit
            {max_inflight, 100},

            %% Retry interval for redelivering QoS1/2 messages.
            {unack_retry_interval, 60},

            %% Awaiting PUBREL Timeout
            {await_rel_timeout, 20},

            %% Max Packets that Awaiting PUBREL, 0 means no limit
            {max_awaiting_rel, 0},

            %% Statistics Collection Interval(seconds)
            {collect_interval, 0},

            %% Expired after 2 days
            {expired_after, 48}

        ]},
        %% Session
        {queue, [
            %% Max queue length. enqueued messages when persistent client disconnected,
            %% or inflight window is full.
            {max_length, 100},

            %% Low-water mark of queued messages
            {low_watermark, 0.2},

            %% High-water mark of queued messages
            {high_watermark, 0.6},

            %% Queue Qos0 messages?
            {queue_qos0, true}
        ]}
    ]},
    %% Broker Options
    {broker, [
        %% System interval of publishing broker $SYS messages
        {sys_interval, 60},

        %% Retained messages
        {retained, [
            %% Expired after seconds, never expired if 0
            {expired_after, 0},
            %% Max number of retained messages
            {max_message_num, 100000},
            %% Max Payload Size of retained message
            {max_playload_size, 65536}
        ]},
        %% PubSub
        {pubsub, [
            %% default should be scheduler numbers
            {pool_size, 16} %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ]},
        %% Bridge
        {bridge, [
            %%TODO: bridge queue size
            {max_queue_len, 10000},

            %% Ping Interval of bridge node
            {ping_down_interval, 1} %seconds
        ]}
    ]},
    %% Modules
    {modules, [
        %% Client presence management module.
        %% Publish messages when client connected or disconnected
        {presence, [{qos, 0}]}

        %% Subscribe topics automatically when client connected
        %% {autosub, [{"$Q/client/$c", 0}]}

        %% Rewrite rules
        %% {rewrite, [{file, "etc/rewrite.config"}]}

    ]},
    %% Plugins
    {plugins, [
        %% Plugin App Library Dir
        {plugins_dir, "./plugins"},

        %% File to store loaded plugin names.
        {loaded_file, "./data/loaded_plugins"}
    ]},
    %% Listeners
    {listeners, [
        {mqtt, 1883, [
            %% Size of acceptor pool
            {acceptors, 64}, %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Maximum number of concurrent clients
            {max_clients, 1000000}, %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Socket Access Control
            {access, [{allow, all}]},
            %% Connection Options
            {connopts, [
                %% Rate Limit. Format is 'burst, rate', Unit is KB/Sec
                {rate_limit, "100,50"} %% 100K burst, 10K rate
            ]},
            %% Socket Options
            {sockopts, [
                {backlog, 1024}
                %Set buffer if hight thoughtput
                %{recbuf, 4096},
                %{sndbuf, 4096}
                %{buffer, 4096},
            ]}
        ]},
        {mqtts, 8883, [
            %% Size of acceptor pool
            {acceptors, 4},
            %% Maximum number of concurrent clients
            {max_clients, 512},
            %% Socket Access Control
            {access, [{allow, all}]},
            %% SSL certificate and key files
            {ssl, [{certfile, "etc/ssl/ssl.crt"},
                   {keyfile,  "etc/ssl/ssl.key"}]},
            %% Socket Options
            {sockopts, [
                {backlog, 1024}
                %{buffer, 4096},
            ]}
        ]},
        %% HTTP and WebSocket Listener
        {http, 8083, [
            %% Size of acceptor pool
            {acceptors, 4},
            %% Maximum number of concurrent clients
            {max_clients, 64},
            %% Socket Access Control
            {access, [{allow, all}]},
            %% Socket Options
            {sockopts, [
                {backlog, 1024}
                %{buffer, 4096},
            ]}
        ]}
    ]},

    %% Erlang System Monitor
    {sysmon, [

        %% Long GC, don't monitor in production mode for:
        %% https://github.com/erlang/otp/blob/feb45017da36be78d4c5784d758ede619fa7bfd3/erts/emulator/beam/erl_gc.c#L421
        {long_gc, false}, %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% Long Schedule(ms)
        {long_schedule, 50}, %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% 8M words. 32MB on 32-bit VM, 64MB on 64-bit VM.
        %% 8 * 1024 * 1024
        {large_heap, 8388608},%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% Busy Port
        {busy_port, true}, %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% Busy Dist Port
        {busy_dist_port, true} %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      ]}
 ]}
].

````````````````````````````````````````````````````````````````````

## 系统内核参数的配置
参考[https://github.com/emqtt/emqttd/wiki/linux-kernel-tuning](linux kernel tuning)
服务器端为了可以得到百万的并发量，需要配置两个文件：
1 /etc/sysctl.conf

``````````````````````````````````````````
# max file descriptor
fs.file-max = 1000000

# Increase number of incoming connections
net.core.somaxconn = 65536

``````````````````````````````````````````
为了使服务器得到更好的优化，作者提供了集中配置方案，根据自己的情况选择即可。进行上面的配置之后，在终端执行sysctl -p 使之生效。

2 /etc/security/limits.conf
添加两行：
```````````````````````````````````````````

*        soft   nofile      1000000
*        hard   nofile      1000000

```````````````````````````````````````````
完了使用ulimit -n来确认设置成功。
客户端要模拟百万的客户端连接，需要进行一些设置，一台机器的总的端口是65535个，去除系统占有的，我们可以设置500-65535之间可以作为客户端连接的端口。可以在终端执行下面命令：
````````````````````````````````
sysctl -w net.ipv4.ip_local_port_range="500 65535"
echo 1000000 > /proc/sys/fs/nr_open
````````````````````````````````
也可以把相关的内容直接写到相应的文件中，端口范围写在/etc/sysctl.config中。
## 错误记录：
1,
``````````````````````````````````````````````````
=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
** Generic server <0.618.0> terminating 
** Last message in was {inet_async,#Port<0.7400>,52627,{ok,#Port<0.426389>}}
** When Server state == {state,#Port<0.7400>,
                               #Fun<esockd_transport.2.94509882>,
                               #Fun<esockd_listener_sup.1.16895020>,
                               ["0.0.0.0",58,"1883"],
                               <0.603.0>,#Fun<esockd_server.0.76791649>,
                               {gen_logger,lager_logger,8},
                               52627,0}
** Reason for termination == 
** {'module could not be loaded',
       [{lager_logger,error,
            ["acceptor on ~s suspend 100(ms) for ~p emfile errors!!!",
             [["0.0.0.0",58,"1883"],0]],
            []},
        {esockd_acceptor,sockerr,2,
            [{file,"src/esockd_acceptor.erl"},{line,169}]},
        {gen_server,try_dispatch,4,[{file,"gen_server.erl"},{line,615}]},
        {gen_server,handle_msg,5,[{file,"gen_server.erl"},{line,681}]},
        {proc_lib,init_p_do_apply,3,[{file,"proc_lib.erl"},{line,240}]}]}

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: /root/emqttd/rel/emqttd/lib/gen_logger-1.0/ebin/lager_logger.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: lager_logger.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: /root/emqttd/rel/emqttd/lib/gen_logger-1.0/ebin/lager_logger.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: lager_logger.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: /root/emqttd/rel/emqttd/lib/gen_logger-1.0/ebin/lager_logger.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: lager_logger.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: /root/emqttd/rel/emqttd/lib/stdlib-2.6/ebin/lib.beam. Function: get_file. Process: code_server.

=ERROR REPORT==== 7-Jan-2016::15:22:59 ===
File operation error: emfile. Target: lib.beam. Function: get_file. Process: code_server.

``````````````````````````````````````````````````
[https://github.com/emqtt/emqttd/issues/253](issues)
"emfile error" means that the broker cannot open new file descriptor.拿就要检查你的文件个数的设置哪有没有设置为百万级的。

2,
`````````````````````````````````````````````````
=ERROR REPORT==== 7-Jan-2016::19:29:57 ===
File operation error: system_limit. Target: /root/emqttd/rel/emqttd/lib/os_mon-2.4/ebin/lager_logger.beam. Function: get_file. Process: code_server.
=ERROR REPORT==== 7-Jan-2016::16:09:31 ===
** Generic server <0.636.0> terminating 
** Last message in was {inet_async,#Port<0.7402>,6525,{error,system_limit}}
** When Server state == {state,#Port<0.7402>,
                               #Fun<esockd_transport.2.94509882>,
                               #Fun<esockd_listener_sup.1.16895020>,
                               ["0.0.0.0",58,"8083"],
                               <0.631.0>,#Fun<esockd_server.0.76791649>,
                               {gen_logger,lager_logger,8},
                               6525,0}
** Reason for termination == 
** {accept_error,system_limit}
`````````````````````````````````````````````````
这个参考比较老了，[http://blog.yufeng.info/archives/1851] and [http://blog.yufeng.info/archives/1380]
上面修改ulimit -n 1000000 不能直接在shell中修改，应该在文件/etc/security/limits.conf 中修改.
确认包含下面的内容：
`````````````````````
root soft nofile 1000000
root hard nofile 1000000
* soft nofile 1000000
* hard nofile 1000000
* hard    nproc           1000000
* soft    nproc           1000000
```````````````````````
修改之后通过重现登录shell, 用ulimit -Hn和ulimit -Sn确认修改已生效

3,
````````````````````````````````
(emqttd@127.0.0.1)2> 
=INFO REPORT==== 19-Jan-2016::22:17:28 ===
    alarm_handler: {set,{process_memory_high_watermark,<0.101.0>}}
````````````````````````````````
这是erlang的内存管理模块memsup提示的问题, memsup是一个管理系统和单个进程的内存使用情况的进程,他属于os_mon application的一部分, 而这个app又依赖erlang的sasl运用.sasl(Simple Authentication and Security Layer)运用可以记录系统进程的相关日志,如进程启动,结束和崩溃错误等信息. memsup这个进程会周期性执行一个内存检查,主要包括两方面:
a) 如果整个系统可获得的内存的一定比例都已经被分配,那么就会报警, 这个比例由参数{system_memory_high_watermark, []}决定.
b) 如果erlang的任何一个进程分配的内存超过系统总内存的一定比例, 那么就会报警, 这个比例又{process_memory_high_watermark, []}决定.
    所以我们看上面的 INFO REPORT, 里面指出,这个消息是又sasl的alarm_handler报出的消息, 说明进程pid为<0.101.0>的进程分配过大.为了找到这个进程,我们在log目录下面的sasl日志中查找这个pid,就找到下面的消息:
``````````````````````````
=PROGRESS REPORT==== 19-Jan-2016::23:14:23 ===
          supervisor: {local,lager_sup}
             started: [{pid,<0.101.0>},
                       {id,lager},
                       {mfargs,{gen_event,start_link,[{local,lager_event}]}},
                       {restart_type,permanent},
                       {shutdown,5000},
                       {child_type,worker}]
``````````````````````````
从上面这里我们可以得到很多信息, PROGRESS REPORT表示这个描述一个进程运行的描述, 这个进程的pid就是上面提示内存使用警报的那个,进程id是lager, 他的监督者是lager_sup,started是他在supervisor中的启动配置参数. 在mfargs中,我们可以知道这是在gen_event:start_link({local, lager_event})中启动的.根据这些提示,我们知道问题就在lager中, 在emqttd的配置文件中,我们发现lager的显示级别是error,而在emqttd_access_Control中只要deny的都会作为error,把这些信息全部写入到emqttd_error.log中去了,耗费了很大的内存.应该把这个关掉.

[congleetea]:    http://congleetea.github.io  "congleetea"
