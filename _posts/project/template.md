---
layout: post
title: add interval to write the topic selectively 
category: project 
description: 
---
1 思路： 顺着topic的走向，关注a）怎么在认证的时候读取表示存取的值？ b）怎么将信息写入session？下次来topic时怎么读取出来作比较？
2 interval 的级别：
intervals = {
    "1D" : 11,
    "12h": 10,
    "6h" :  9,
    "1h" :  8,
    "30m":  7,
    "10m":  6,
    "5m" :  5,
    "1m" :  4,
    "30s":  3,
    "10s":  2,
    "5s" :  1,
    "1s" :  0,
    "default": 3,
    "store_interval": seconds['30s'],
    "run_interval": 5*60
}

3 emqttd_message:from_packet(ClientId, Packet) : 获得消息，保存成记录 
    #mqtt_message{msgid     = msgid(Qos),
                  topic     = Topic,
                  retain    = Retain,
                  qos       = Qos,
                  dup       = false,
                  payload   = Msg, 
                  timestamp = os:timestamp()}.
随后                  
emqttd_procotol:publish(Packet = ?PUBLISH_PACKET(?QOS_0, _PacketId),
        #proto_state{client_id = ClientId, session = Session}) ->
    emqttd_session:publish(Session, emqttd_message:from_packet(ClientId, Packet));
通过emqttd_session:publish 发布出去。针对消息的Qos类型进行分布：
%%------------------------------------------------------------------------------
%% @doc Publish message
%% @end
%%------------------------------------------------------------------------------
-spec publish(pid(), mqtt_message()) -> ok | {error, any()}.
publish(_SessPid, Msg = #mqtt_message{qos = ?QOS_0}) ->
    %% publish qos0 directly
    emqttd_pubsub:publish(Msg);

publish(_SessPid, Msg = #mqtt_message{qos = ?QOS_1}) ->
    %% publish qos1 directly, and client will puback automatically
    emqttd_pubsub:publish(Msg);

publish(SessPid, Msg = #mqtt_message{qos = ?QOS_2}) ->
    %% publish qos2 by session 
    gen_server2:call(SessPid, {publish, Msg}, ?PUBSUB_TIMEOUT).

针对Qos0和Qos1，直接使用emqttd_pubsub:publish进行发布，而Qos2则使用gen_server2:call同步发布。
%%------------------------------------------------------------------------------
%% @doc Publish to cluster nodes
%% @end
%%------------------------------------------------------------------------------
-spec publish(Msg :: mqtt_message()) -> ok.
publish(Msg = #mqtt_message{from = From}) ->
    trace(publish, From, Msg),
    Msg1 = #mqtt_message{topic = To}
               = emqttd_broker:foldl_hooks('message.publish', [], Msg), <!-- 这里有一个hook，执行'message.publish'的插件，也就是执行mongodb的写入.因此我们应该在这之前决定是否将message写入到mongodb -->

    %% Retain message first. Don't create retained topic.
    case emqttd_retainer:retain(Msg1) of
        ok ->
            %% TODO: why unset 'retain' flag?
            publish(To, emqttd_message:unset_flag(Msg1));
        ignore ->
            publish(To, Msg1)
     end.

publish(To, Msg) ->
    lists:foreach(fun(#mqtt_topic{topic = Topic, node = Node}) ->
                    case Node =:= node() of
                        true  -> ?ROUTER:route(Topic, Msg);
                        false -> rpc:cast(Node, ?ROUTER, route, [Topic, Msg])
                    end
                end, match(To)).

4 打印log来看：

Publish Message(Q0, R0, D0, MsgId=undefined, PktId=undefined, From=lcpub-0, Topic=v1/ccccf572ce7d21fd1b000003/channel/smartLight_0/data/time_0)
14:26:40.422 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/connected">>,presence,0,false,false,false,<<"{\"clientid\":\"lcpub-0\",\"username\":\"cc77a23abc313eaa05429c546ac78957\",\"ipaddress\":\"127.0.0.1\",\"session\":false,\"protocol\":3,\"connack\":0,\"ts\":1452580000}">>,{1452,580000,421959}}
14:26:40.422 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/connected">>,presence,0,false,false,false,<<"{\"clientid\":\"lcpub-0\",\"username\":\"cc77a23abc313eaa05429c546ac78957\",\"ipaddress\":\"127.0.0.1\",\"session\":false,\"protocol\":3,\"connack\":0,\"ts\":1452580000}">>,{1452,580000,421959}}
14:26:40.422 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/connected">>,presence,0,false,false,false,<<"{\"clientid\":\"lcpub-0\",\"username\":\"cc77a23abc313eaa05429c546ac78957\",\"ipaddress\":\"127.0.0.1\",\"session\":false,\"protocol\":3,\"connack\":0,\"ts\":1452580000}">>,{1452,580000,421959}}
14:26:40.422 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"v1/ccccf572ce7d21fd1b000003/channel/smartLight_0/data/time_0">>,<<"lcpub-0">>,0,false,false,false,<<"20152125">>,{1452,580000,422357}}
14:26:40.422 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"v1/ccccf572ce7d21fd1b000003/channel/smartLight_0/data/time_0">>,<<"lcpub-0">>,0,false,false,false,<<"20152125">>,{1452,580000,422357}}
14:26:40.422 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"v1/ccccf572ce7d21fd1b000003/channel/smartLight_0/data/time_0">>,<<"lcpub-0">>,0,false,false,false,<<"20152125">>,{1452,580000,422357}}
14:26:40.460 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/disconnected">>,presence,0,false,false,false,<<"{\"clientid\":\"lcpub-0\",\"reason\":\"normal\",\"ts\":1452580000}">>,{1452,580000,460564}}
14:26:40.460 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/disconnected">>,presence,0,false,false,false,<<"{\"clientid\":\"lcpub-0\",\"reason\":\"normal\",\"ts\":1452580000}">>,{1452,580000,460564}}
14:26:40.460 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/disconnected">>,presence,0,false,false,false,<<"{\"clientid\":\"lcpub-0\",\"reason\":\"normal\",\"ts\":1452580000}">>,{1452,580000,460564}}
14:26:40.889 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"1 seconds">>,{1452,580000,889714}} 
14:26:40.889 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"1 seconds">>,{1452,580000,889714}} 
14:26:40.889 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"1 seconds">>,{1452,580000,889714}} 
14:26:40.889 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:40">>,{1452,580000,889950}}
14:26:40.890 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:40">>,{1452,580000,889950}}
14:26:40.890 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:40">>,{1452,580000,889950}}
14:26:41.889 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"2 seconds">>,{1452,580001,889713}} 
14:26:41.889 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"2 seconds">>,{1452,580001,889713}} 
14:26:41.889 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"2 seconds">>,{1452,580001,889713}} 
14:26:41.889 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:41">>,{1452,580001,889943}}
14:26:41.890 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:41">>,{1452,580001,889943}}
14:26:41.890 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:41">>,{1452,580001,889943}}
14:26:42.889 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"3 seconds">>,{1452,580002,889715}} 
14:26:42.889 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"3 seconds">>,{1452,580002,889715}} 
14:26:42.889 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/uptime">>,broker,0,false,false,false,<<"3 seconds">>,{1452,580002,889715}} 
14:26:42.889 [error] emqttd_pubsub:241 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:42">>,{1452,580002,889905}}
14:26:42.889 [error] emqttd_pubsub:244 MESG after  hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:42">>,{1452,580002,889905}}
14:26:42.890 [error] emqttd_pubsub:255 MESG before hooks: ********************{mqtt_message,undefined,undefined,<<"$SYS/brokers/emqttd@127.0.0.1/datetime">>,broker,0,false,false,false,<<"2016-01-12 14:26:42">>,{1452,580002,889905}}  "\"}"}"\"}"}"\"}"}"\"}"}"\"}"}"\"}"}

我们抽出一条来看mqtt_message 记录的类型：
对比类型：
-record(mqtt_message, {
    msgid           :: mqtt_msgid(),      %% Global unique message ID
    pktid           :: mqtt_pktid(),      %% PacketId
    topic           :: binary(),          %% Topic that the message is published to
    from            :: binary() | atom(), %% ClientId of publisher
    qos    = 0      :: 0 | 1 | 2,         %% Message QoS
    retain = false  :: boolean(),         %% Retain flag
    dup    = false  :: boolean(),         %% Dup flag
    sys    = false  :: boolean(),         %% $SYS flag
    payload         :: binary(),          %% Payload
    timestamp       :: erlang:timestamp() %% os:timestamp
}).

14:26:40.422 [error] emqttd_pubsub:241 MESG before hooks: ********************
{mqtt_message,undefined,
undefined, <!-- msgid -->
<<"$SYS/brokers/emqttd@127.0.0.1/clients/lcpub-0/connected">>, <!-- Topic -->
presence, <!-- from -->
0,        <!-- qos -->
false,    <!-- retain-->
false,    <!-- dup -->
false,    <!-- sys -->
<<"{\"clientid\":\"lcpub-0\",\"username\":\"cc77a23abc313eaa05429c546ac78957\",\"ipaddress\":\"127.0.0.1\",\"session\":false,\"protocol\":3,\"connack\":0,\"ts\":1452580000}">>, <!--  payload -->
{1452,580000,421959}} <!-- timestamp -->


-----------------------------------------------------
1 在redis的tokens中加入一个字段：writeFrequency:10 表示写入频率是十秒钟一次。
2 在mongodb判断是否存的时候从ets等属于那个client的地方读取出上一时刻的时间戳进行比较，存完之后，在把新的时间戳再次存到ets等地方，将原来的覆盖。 
在emqttd_sm中有对session的操作。session的信息是保存在mnesia中的。 client的监管信息是放在dist中。
emqttd_Session中的session记录中，有一个字段packet_id表示上一个packet的packet id，那说明每一个packet来了都会改变这个值。那我们是不是可以在这里加一个字段。注意函数next_packet_id






我们的topic可以知道client_id，根据这个id可以在mnesia的表session中查询到这个客户端对应的session信息。假设我们这里的client_id 是<<"kkkkkkkkkkkkkkkkkkkkkkkk0">>，那么我们通过：
(emqttd@127.0.0.1)18> Fe = fun() -> mnesia:read({session, <<"kkkkkkkkkkkkkkkkkkkkkkkk0">>}) end.
#Fun<erl_eval.20.54118792>
(emqttd@127.0.0.1)19> mnesia:transaction(Fe).
{atomic,[{mqtt_session,<<"kkkkkkkkkkkkkkkkkkkkkkkk0">>,
                       <0.633.0>,false}]}
这三个量表示client_pid, session_pid, session的永久性。




3 每次针对某个客户端和他的topic，第一次认证之后会把认证结果写入到进程字典中，下次topic来了之后，首先去进程字典中查询，如果有了那就说明之前已经对这个客户端的这个topic已经认证过了，那这一次就不用认证了，如果没有那就重新认证，这样就可以减少每次都去redis中读取数据了。 
%% PUBLISH ACL is cached in process dictionary.
check_acl(publish, Topic, Client) ->
    case get({acl, publish, Topic}) of
        undefined ->
            AllowDeny = emqttd_access_control:check_acl(Client, publish, Topic),
            %% put(last_timestamp, os:timestamp()),
            put({acl, publish, Topic}, AllowDeny),
            AllowDeny;
        AllowDeny ->
            AllowDeny
    end;

4 取writeFrequency应该在acl的时候取回来，因为：
user的根本不需要publish信息，所以，没有必要也去执行一下查询这个字段的操作。







[congleetea]:    https://congleetea.github.io  "congleetea"
[1]:    {{ page.url}}  ({{ page.title }})
