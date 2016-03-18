---
layout: post
title: erlang编程时的小记 
category: opinion
description: 在编程的时候，很多细节，特别是函数传递的结构很容易出现匹配问题，所以这里的使用的时候，把一些细节记录下来方便往后查阅，不用每次都打log查看。
---

#### 获取参数

lists:keyfind(Key, N, TupleList) -> Tuple | false  获得tuple
proplists:get_value(Key, List, Default) -> term()  直接Key的值，如果没有可用默认值


#### lager的使用

除了系统文件中的配置外，还要在rebar.config中加入：
{erl_opts, [debug_info, {parse_transform, lager_transform}]}.
