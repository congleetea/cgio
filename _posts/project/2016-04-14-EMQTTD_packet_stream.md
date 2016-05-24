---
layout: post
title: mqtt消息发布和订阅的消息流 
description:mqtt消息发布和订阅的消息流 
category: project 
---

前面在讲述socket的建立和连接的过程中,讲到在acceptor中通过controlling_process将socket的控制权交到了clientPid手中,这样在emqttd_client.erl中,通过handle_info({inet_async,_Sock,_Ref,{ok, Data}},State)进而利用函数received获取从客户端发来的数据请求,这些请求包括总共14种报文.

## 1
获取数据之后的第一件事就是解析数据包,利用的是emqttd的模块 emqttd_parser.erl,这一步严格按照MQTT协议的规定对包的每一个字段就行解析,这对我们理解packet是很有用的.这里顺便提一下,对于我们接收到的包我们要进行解析,而我们要发送出去的包相对的就要进行序列化,这一步是在emqttd的模块emqttd_serializer.erl里面完成的.

对包解析之后会返回{ok,#mqtt_packet{header=Header,variable=Variable,payload=Payload},Rest},接下来就是对这个经过解析之后的mqtt_packet记录尽心处理了.

## 2 
接下来的处理首先到emqttd_procotol.erl里的received中,首先received函数对于包的类型匹配不同的received函数:对于CONNECT包,只允许客户端发送一次,初始时的协议状态#proto_state里connected=false,一旦接受之后我们首先将其置为true,接着利用process函数进行处理. 而对于其他的packet,我们首先验证这个packet的有效性,有限性的验证就是看这个packet的topic是否符合要求,符合要求之后才进入process函数进行处理.
下面我们将对各种PACKET来进行分析.

## 3 
PACKET主要就是三大类:CONNECT,PUBLISH和 SUBSCRIBE,其他的都是围绕这三类展开的,比如各类消息的响应包(CONNACK,PUBACK,...),所以我们重点看这三类.

### 3.1 CONNECT packet
验证connect(验证协议版本和名字是否合法,验证客户端是否符合要求),根据验证结果获取相应的返回码0-连接被接受,1-协议不可接受,2-ClientId不合法. 
  |
  V
认证客户端(有不同的方式,可以用户自定义)
  |
  V
如果没有ClientId的话,broker自动生成一个ClientId
  |
  V
为这个客户端启动一个session(session的state包括pool,id,monitors) 
注意你的connect包里面的CleanSession是true|false,在启动session的时候都会决定启动什么类型的(永久的还是暂时的)session.
session的创建其实就是将相应的信息写进mnesia中.
永久session会重用以前的session, 而暂时的就会先把已有的destroy掉,然后建立新的session,建立session时会产生一个session记录:#mqtt_session{client_id,sess_pid,persistent},然后将这个记录写进mnesia中.最后返回{ok,SessPid,true|false},true|false表示session永久还是暂时.
  |
  V
接着是注册client,其实就是把记录#mqtt_client写进ets表mqtt_client中.
  |
  V
接着处理长连接问题, 向self()发送{keepalive,start,Interval},在emqttd_client:handle_info中处理.里面调用emqttd_keepalive:start(StatFun,Interval,{keepalive,check}),函数里面会设定一个定时器,如果到时了还没有接到客户端的任何packet(正常的请求包和PINGREQ包),就会发送第三个参数的消息给服务器,然后调用emqttd_keepalive:check来检查状态,确定是否断开连接.
  |
  V
结束之后返回了{返回码,SessPresent,State}.
接着执行connected的hook
  |
  V
发送CONNACK包给客户端.
这个过程需要对CONNACK包进行序列化,在通过socket发送出去.
  |
  V
到此,这个对CONNECT包的处理过程就全部结束了.


### 3.2 PUBLISH packet 
首先进行访问控制的授权(ACL),允许之后才真正的处理发布问题.
  |
  V
处理PUBLISH是根据qos等级来处理的.各种qos等级的PUBLISH首先都要通过emqttd_message:from_packet从packet中组出#mqtt_message的记录来.接下来就是这个记录进行操作.
下面对qos=1的尽心解析,这个比较简单.
qos=1 |
      V
通过emqttd_session:publish(Session,Msg)处理,注意这里已经进入到了Session层了.
      |
      V
直接通过emqttd:publish(Msg)发布 
      |
      V
通过emqttd_server:publish(Msg)发布.
      |
      V
运行publish的hook.
      |
      V
判断是否对消息进行retain,注意如果retain的消息为空,那么以前的就会被清除.
retain消息其实就是将消息写进mnesia的retained_message表中.
      |
      V
retain完消息之后,需要把这个消息的retain和dup置为false,组成新的Msg2,接着对这个消息操作.
      |
      V
接着使用emqttd_pubsub:publish(Topic,Msg2)
这时候消息就到了pubsub环节了.这一步会通过router找出这个topic的所有订阅者,然后给这些订阅者的进程pid(这时候还在session层里面,所以有emqttd_session模块处理)发送{dispatch,Topic,Msg2},订阅者使用handle_info来处理dispatch信息.
      |
      V
emqttd_session:handle_info({dispatch,...})会通过发布者和订阅者的qos等级选择二者中较小的qos作为最终发布的qos等级.
      |
      V
向clientPid发送{deliver,Msg2}消息,emqttd_client.erl通过handle_info来处理deliver.
      |
      V
emqttd_client.erl的handle中调用emqttd_protocol:send(Message,ProtoState)进行投递.
      |
      V
emqttd_protocol:send中,首先执行'message.delivered'的hook,
接着把Msg组成packet,接着通过emqttd_serializer:serialize(Packet)组成二进制包Data,然后通过Connection:async_send(Data)通过socket发送出去.
      |
      V
到此为止,PUBLISH的处理就结束了.而相对的就是SUBSCRIBE的packet.

下面解析qos=1|2的类型:

首先,在emqttd_protocol:publish中,使用with_puback来处理,和qos=0的PUBLISH一样,首先要利用emqttd_message:from_packet从packet中组出#mqtt_message,后面对这个消息进行处理.
      |
      V
接着转移到emqttd_session中,使用emqttd:publish()
      |
      V
emqttd:publish(Msg) 
qos=1直接发布出去,客户端会自动puback.
后面的步骤和qos=1一样的,不同的就是在emqttd_protocol中with_puback函数最后会执行:
send(?PUBACK_PACKET(Type,PacketId),State).
这样会组成PUBACK包,通过这个session发送给连接这个socket的客户端.

对于qos=2的类型,在emqttd_session:publish中,使用gen_server2:call(SessPid,{publish,Msg},?PUBSUB_TIMEOUT)发送消息给SessPid,调用handle_call来处理.
    |
    V
首先将#session里的awaiting_rel用来表示这个包要等待确认,并且有一个等待确认延时,如果在规定的时间内没有得到PUBREL的响应,就会采取一些动作.接着会通过check_awaiting_rel(Session)来检查这个session中等待rel响应的大小,如果这个值已经超过了最大的限制,那么就提示该session中等待rel确认的消息太多了,发送{error,dropped}进行删除.如果还有空间,那就通过:
maps:put(PktId,{Msg,TRef},Awaiting)将定时信息,message全部写进映射里面.
    |
    V
最后在emqttd_procotol:with_puback中,最后使用send发送相应给客户端,表示这个包被收到了.
这个包应该叫PUBREL,但是也是通过send(?PUBACK_PACKET(Type,PacketId),State)发送出去的.

上面完成了PUBLISH的处理了.对于qos=0的情况,我们不用管后面的事了,但是qos=1|2的情况,我们要等待接受PUBREL的消息.
这样就到了emqttd_session的handle_cast里面了,这里首先查找这个PktId对应的AwaitingAck,里面有一个等待REL的定时器,
接着,先取消掉这个定时器,建立一个等待comp的新的定时器.这个定时器其实是为了计算订阅这个topic的客户端给出的相应.因为作为broker,它要给发送者一个COMP的相应,同时broker也可能会接受到订阅者的COMP消息.

当接收到PUBREL消息之后,同样会先取消对应的定时器,接着这个时候才把消息发布出去,并删除映射中的AwaitingRel

### 3.3 SUBSCRIBE packet 
SUBSCRIBE需要broker将对应的消息分发给订阅者.
在对SUBSCRIBE的解析中,最重要的就是TopicTable,表示这个客户端要订阅那些topic.
在emqttd_protocol:process中,首先对这个客户端进行访问控制验证,看是否有权限去订阅这个topic,对每个topic进行验证之后会得到一个有allow或者deny组成的list,只要这个list里面有一个deny,也就是说对一个topic没有权限,那么我们就会拒绝它订阅所有的消息,并send(?SUBACK_PACKET,...).反之,则利用emqttd_session:subscribe(Session,PacketId,TopicTable)来进行下面的操作.
  |
  V
emqttd_session:subscribe里定义了AckFun:向self()发送{suback}消息,这个函数是作为参数连同{subscribe,TopicTable,AckFun}发送的,这样通过handle_cast来处理
  |
  V
handle_cast会进行下面的操作:
运行subscribe的hook
  |
  V
我们知道TopicTable里面包含的是{Topic,Qos},接着在dict中查找这个topic的订阅信息qos,对比这个Qos和原来的dict,如果不同的话要对这个进行更新,也就是把新的订阅信息写进dict,如果根本就没有查到这个topic相关的,也就说明是这个订阅在dict中还没有保留信息,接下来emqttd:subscribe(ClientId,Topic,Qos)(引用emqttd_server:subscribe).
  |
  V
从一个mqtt session订阅:
handle_call({subscribe...})这里会执行:
添加subscriber,也就是向#mqtt_subscription写进mnesia的subscription表中.
执行订阅,首先匹配ets的表subscribed中{SubPid,Topic},如果没有任何匹配就说明还没有过订阅,则执行emqttd_pubsub:subscribe之后将这个{SubPid,Topic}写进ets的subscribed表中(这个表有什么毛线用处?难道是为了清除用?.....,这个表和下面的subscriber都是在emqttd_pubsub_sub中创建的.).
  |
  V
emqttd_pubsub:subscribe(Topic,SubPid):这里将add_subscriber_(Topic,SubPid):首先查看ets表subscriber中有没有Topic这个key,如果有的话说明这个topic已经被其他client订阅了,这时候把我们这个订阅关系写进去即:ets:insert(subscriber,{Topic,SubPid});如果没有的话,说明这个topic还没有被任何现有的client订阅,这样的话,首先要调用emqttd_router:del_route(Topic,node())删除mnesia中对这个topic的路由,添加一个新的路由,在把订阅关系写进ets的subscriber表中.
  |
  V
上面完成之后,回到emqttd_session中,接着emqttd_retainer:dispatch(Topic,self()).将已有的retained的消息投递给订阅者.
最后dict:store(Topic,Qos,SubDict)保留这些信息.
