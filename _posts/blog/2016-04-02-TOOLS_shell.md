---
layout: post
title: tools 之 shell 
description: shell 
category: blog
---

### shell 括号使用
#### ()

#### (())

#### []

#### [[]]

#### {}

#### {{}}


### 条件表达式

条件表达式引用变量要带$

#### 文件表达式

```````````
if [ -f  file ]    如果文件存在
if [ -d ...   ]    如果目录存在
if [ -s file  ]    如果文件存在且非空 
if [ -r file  ]    如果文件存在且可读
if [ -w file  ]    如果文件存在且可写
if [ -x file  ]    如果文件存在且可执行 
```````````

#### 整数变量表达式

````````````
if [ int1 -eq int2 ]    如果int1等于int2   
if [ int1 -ne int2 ]    如果不等于    
if [ int1 -ge int2 ]       如果>=
if [ int1 -gt int2 ]       如果>
if [ int1 -le int2 ]       如果<=
if [ int1 -lt int2 ]       如果<
````````````
#### 字符串变量表达式

``````````
If  [ $a = $b ]                 如果string1等于string2
                                字符串允许使用赋值号做等号
if  [ $string1 !=  $string2 ]   如果string1不等于string2       
if  [ -n $string  ]             如果string 非空(非0），返回0(true)  
if  [ -z $string  ]             如果string 为空
if  [ $sting ]                  如果string 非空，返回0 (和-n类似) 
``````````

