---
layout: post
title: rabbitmq使用celery驱动
category: project
description: 总结rabbitmq和celery
---

## 为什么要用rabbitmq

### 使用场合

我们知道大型的网站有时候不得不做一些比较耗时的工作，举个例子：新浪微博里面一个用户发布了一条信息，那就会向所有关注他的用户都推送一条通知。但是如果这个用户的粉丝有很多，比如有一万个，如果按通常的做法，web就要查询一万次，执行完之前用户才能看到信息，否则就看不到。现在我们就换一种方式，用户发帖之后，只需要发送一条消息给一个队列，然后，在另一端启动多个worker来执行这个推送任务。这样就会方便很多了。
另外一个就是定时任务，就是在服务器上设定定时任务，按期执行一些任务，用户少的话这没什么，但是如果用户很多，或者有多个服务器，如何管理和实现这些功能就会变得很困难。这里还有很多事情要考虑：①查看定时任务的执行情况.比如执行是否成功，当前状态，执行花费的时间；②一个友好的界面或者命令行下实现添加,删除任务；③怎么样简单实现不同的机器设定不同种任务,某些机器执行不同的队列；④假如你需要生成一个任务怎么样不阻塞剩下来的过程(异步了呗)；⑤怎么样并发的执行任务。

要实现这些事情可以通过rabbitmq来实现。rabbitmq是个什么东西呢？

rabbitmq是一个消息代理，一个消息的媒介。他可以为用户的运用提供一个通用的消息发送和接受平台，并且保证信息在传输过程中的安全。其实就是一个消息系统，它允许软件运用相互连接和扩展，这些运用可以相互连接起来组成一个更大的网络，或者将用户设备和数据进行连接，通过将消息的发送(消息的产生源)和接受(接受消息并做出相应的反应)分离来实现运用程序的异步和解耦。这适合在什么场合呢？比如数据投递，非阻塞操作，推送通知；或者实现发布/订阅，异步处理，或者工作队列。这些都属于消息系统的模式。

现在我们就这些运用场合在实际生活中找一个例子： 寄信和收信，以及邮局（邮递员）所扮演的工作。寄信者要把信寄到收信人手里，可以自己把信送过去，也可以通过邮局送过去。前者的特点是你把信送给对方之前你都是“阻塞的”，不能去做其他的事（这就是同步的操作）,想象一下如果你有十封信，或者更多，那你不是要跑断腿。而后者呢？只要你把信，不管一封还是一百封给了邮局，邮局那边就会进行排队分类，接着由很多投递员去执行投递任务，而寄信人就可以去做其他的事情了（这就是异步的操作）。这样的方式就把消息的发送和接收进行了分离（也就是解耦），各自可以去做各自的事情了 。

### 技术特点

#### 性能和可靠性

rabbitmq提供多种技术可以供用户在性能要求和可靠性要求之间进行选择。这些技术包括持久性，投递确认（client），发布者证实（服务器）和高可用性。

#### 灵活的路由

消息通过交换机和绑定键来分配消息（任务）会被送到那个队列，被什么worker执行。

#### 集群

在同一个局域网中的多个rabbitmq服务器可以被聚合在一起，作为一个独立的逻辑来代理来使用。

#### 高可用的队列

在同一个集群中，队列可以被镜像到多个机器中，以确保当其中某些硬件出现事故后，你的消息仍然是安全的。

#### 多协议支持

rabbitmq可以支持多种协议中的消息传递，比如mqtt协议的数据，HTTP，STOMP，AMQP协议（实际上rabbitmq就是使用这种协议实现的）。

#### 支持多种客户端（各种语言都可以支出）

python: celery pika

#### 追踪异常

#### 插件系统进行扩展

### 使用
以pika客户端为例：
主要是三个步骤：
1 配置通道建立连接
建立连接: URL = pika.ConnectionParameters('localhost'), connection = pika.BlockingConnection(URL)，
声明通道:channel = connection.channel()，
声明队列:channel.queue_declare(queue='hello')，
声明交换机:channel.exchange_declare(exchange='web_email', type='direct'),
绑定：channel.queue_bind(exchange='ex', queue="q", routing_key="bk")

2 发送信息或者接收信息，接收需要有回调去处理

发送：channel.basic_publish(exchange = "", routing_key="",body="")

接收：
    指定消费关系：channel.basic_consume(consumer_callback, queue='', no_ack=False, exclusive=False, consumer_tag=None, arguments=None)
    启动消费保持状态：channel.start_consuming()

3 关闭连接
connection.close()

### 缺点

rabbitmq 的上面使用方式步骤繁多，过于复杂。他的另外一个客户端celery解决了这些问题，并且做了很多扩展，使用起来更加方便。

## 为什么使用celery

celery结合rabbitmq，redis等其他的多种broker。将消息的生产者，消费者，broker集成在一起，使用起来减少了很多步骤。

### 如何使用celery

celery需要做以下一些事情：

1  选择一个负责消息传输的broker，比如rabbitmq，redis，mongodb等，这里使用的是rabbitmq。
2  安装celery，创建task。
3  启动执行task的worker。

#### celery 的配置

rabbitmq中所有配置，在celery中，只需要在一个配置文件中进行配置之后就好了，主要是队列的定义和消息路由的配置。

```````````
from kombu import Exchange, Queue

ex = Exchange('GraphicControl', type='direct')
CELERY_QUEUES = (               # 意思是由ex交换机，匹配key为recipeTask的消息（task）到recipeTaskQueue队列
    Queue('xxxTaskQueue', exchange=ex, routing_key='xxxTask'),
    Queue('yyyTaskQueue', exchange=ex, routing_key='yyyTask') 
)

```````````
```````````
CELERY_ROUTES = {               #  任务GraphicControl.recipeTask消息由ex交换机处理，发出时带上routing_key为recipeTask。结合上面的队列定义实现推送。
    'GraphicControl.xxxTask': {'exchange': ex, 'routing_key': 'xxxTask'},
    'GraphicControl.yyyTask': {'exchange': ex, 'routing_key': 'yyyTask'}
}

```````````
'GraphicControl.xxxTask'是task的名字。我们在定义task的时候，在装饰器函数@app.Task里面我们可以执行这个task的名字：

````````````
@app.task(name='GraphicControl.xxxTask')
def aTask(topic, datapoint):
````````````
这样的话我们其实就把aTask的名字改成了'GraphicControl.xxxTask'，他的路由已经在CELERY_ROUTES中配置好了，放我们在消息的生产者中使用aTask.delay()函数的时候，消息就会根据路由配置中对GraphicControl.xxxTask的配置，通过交换机ex，附带路由键xxxTask进行分配，然后和队列进行匹配（通过匹配交换机和路由键是否一致）将消息（或者说任务）推送到消息队列xxxTaskQueue中去。等待相应的执行aTask的worker去执行了。
