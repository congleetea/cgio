---
layout: post
title: erlang 的套接字编程 
description: 总结erlang中的套接字编程 
category: blog
---

listen  只是监听某个端口，看端口有没有客户端进行连接，accept则是建立一个可以和客户端进行通信的套接字。往后在服务器和客户端之间的通信都是通过这个 socket来进行的。所以监听套接字可能只有一个，但是accept套接字则会有很多。他们的关系可能这么表示：
客户端1 ----> Listen套接字-----> acceptor1处理客户端1和server的通信问题
             ^  ^  ^   ^  | | | |
 (用同一个Listen套接字)|  | | | -----acceptor2
客户端2 ------  |  |   |  | | -------acceptor3
客户端3 --------   |   |  | ---------acceptor4
客户端4 -----------    |  -----------acceptorn
客户端n ---------------

主控进程：所有来自套接字的消息都会被发送到控制进程。主控进程可以通过gen_tcp:controlling_process(Socket, NewPid) 将主控权交给NewPid。

主动套接字：全部接收数据，有可能被恶意攻击
被动套接字：可以控制每次接受N个字节的数据，必须手动调用gen_tcp:recv(Socket, N)来接受数据。所以被动套接字的作用是控制通往服务器的数据流。

要想接受TCP连接，不许先创建监听套接字，listen监听套接字在TCP服务器的整个声明周期中都必须活着。
