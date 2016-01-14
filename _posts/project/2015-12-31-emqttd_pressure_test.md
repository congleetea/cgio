---
layout: post
title: emqttd pressure test
description: record the configuration and some method to check
category: blog
---
# 参数
## 并发量配置
1 设置最大进程数——vm.args.
    +P 8192  最大进程数： 改成1000000（百万）
    +Q 8192  系统同时存在的端口最大数： 这个首先要更改系统的内核参数，参考[linux kernel tuning](https://github.com/emqtt/emqttd/wiki/linux-kernel-tuning). 需要把可用的端口进行扩展，我是用的是把net.ipv4.ip_local_port_range="500 65535"，将可用端口改在500到65535之间。这样的话就可以连接六万五的并发了。所以这里可以把8192改成六万。 

# 查看技巧
参数
=========================系统配置


etc/vm.args：
----------------------------
1）## max process numbers
   +P 8192——> 1000000（一百万）,系统允许的最大进程数可以通过erlang:system_info(process_limit).来获取。
2) ## Sets the maximum number of simultaneously existing ports for this system
   +Q 8192——> 1000000   [60000(六万)/65536，可以通过erlang:system_info(port_limit).来获得.]这是不行的
R17可以通过系统参数ERL_MAX_PORTS来获得，
-----------------------------

-------------------------------------
3) mqtt 里面{max_clients, 8192}改成百万
-------------------------------------

改小pub的速度，有刚开始一直发改为3s发一次，负载下降很多。---------------------> 问题在于mongodb的操作太快。

4） ## 12 threads/core.每个核12个进程，咱们的八核这里可以是96.
    +A 16——>96


etc/emqttd.config
listeners——>mqtt——>mqtt——>max_clients改为百万。
                       ——>connopts/{rate_limit,"100, 20"},100表示爆发的速度100kb/s，20表示平均的10kb/s。
mqtt——> client/{idle_timeout, 20},单位s，表示socket已经连接，但是没有CONNECT包接收到。
    ——> session/{expired_after, 48},单位h，session的失效时间是2天。
broker——>{sys_interval, 60},broker的$SYS信息更新时间。

mongodb_pool的大小加到1000

只有subscriber时，cpu消耗到0.2/3万3，而加入publish后，cpu负载会持续增加。

******************************************************************************************************
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
======================================================================================
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
=========================================================================
[https://github.com/emqtt/emqttd/issues/253]
"emfile error" means that the broker cannot open new file descriptor.
把vm中的参数，最后的：
## Increase number of concurrent ports/sockets, deprecated in R17
-env ERL_MAX_PORTS 1000000

-env ERTS_MAX_PORTS 1000000

同时使用 ulimit -n 1000000 打开的最大文件数
==========================================================================
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
========================================================
这个参考比较老了，[http://blog.yufeng.info/archives/1851] and [http://blog.yufeng.info/archives/1380]
上面修改ulimit -n 1000000 不能直接在shell中修改，应该在文件/etc/security/limits.conf 中修改
# 确认包含下面的内容：
root soft nofile 1000000
root hard nofile 1000000
* soft nofile 1000000
* hard nofile 1000000
* hard    nproc           1000000
* soft    nproc           1000000
，修改之后通过重现登录shell, 用ulimit -Hn和ulimit -Sn确认修改已生效
========================================================


[congleetea]:    http://congleetea.github.io  "congleetea"
