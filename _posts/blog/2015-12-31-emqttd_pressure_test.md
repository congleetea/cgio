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



[congleetea]:    http://congleetea.github.io  "congleetea"
