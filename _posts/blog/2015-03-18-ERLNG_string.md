---
layout: post
title: erlang 之 string lib 
description: erlang 数据库string
category: blog 
---

string:tokens(String, SeparatorList) -> Tokens
    用SeparatorList中的各个字符将String全部分开。
    利用x和' '将前面的字符分开
    > tokens("abc defxxghix jkl", "x ").
    ["abc", "def", "ghi", "jkl"]

string:strip(String, Direction, Character): 删除String在Direction方向的前，后，或前和后的Character字符
