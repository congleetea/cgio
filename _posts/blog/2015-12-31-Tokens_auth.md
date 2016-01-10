---
layout: post
title: Token auth
description: the principle of token
category: blog
---


|## (AAA) 认证(Authentication)，授权(Aauthorization),记账(Accounting)
    认证是指验证用户的身份与可使用的网络服务；
    授权是指依据认证结果开放哪些网络服务给用户;
    记账是记录用户对各种网络服务的用量。
    首先，认证部分提供了对用户的认证。整个认证通常是采用用户输入用户名与密码来进行权限审核。认证的原理是每个用户都有一个唯一的权限获得标准。由AAA服务器将用户的标准同数据库中每个用户的标准一一核对。如果符合，那么对用户认证通过。如果不符合，则拒绝提供网络连接。
    
# 实例
   redis中的token属性就是用来验证的，

[congleetea]:    http://congleetea.github.io  "congleetea"
