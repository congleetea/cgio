# mnesia

## 关于Mnesia

Mnesia是一个数据库管理系统(Database Management System, DBMS)， 他有以下特点：

1 可以在各个节点之间配置为可复制，试各个节点的数据同步，可以实现容错。

2 表可以进行高度定制，速度需求可以使用内存保存，持久化需求可以保存到磁盘。

## 操作

创建数据库： mnesia:create_schema([node()]),
  |
  |
启动mnesia：ok = mnesia:start(),
  |
  |
创建表，或者复制已有的表
  |
  |
操作数据库

### 创建数据库

一个erlang shell创建一个就行。

mnesia:create_schema(NodeLists)    %% 这样会在NodeLists的所有节点都创建数据库

数据库的名字为 mnesia/node@host 命名的。

### 创建表

mnesia:create_table(Name, Args).

Args:
{type, Type}, Type = set|ordered_set|bag
{disc_copies, NodeList}, %% 既有磁盘副本，又有内存副本
{ram_copies, NodeList},  %% 内存副本
{disc_only_copies, NodeList}, %% 只有磁盘副本，速度较慢。

要创建一个包含erlang记录xxx的表，可以使用{attributes, record_info(fields, xxx)}。

### 数据库查询

和mysql的查询很相似。

#### 获取表中所有数据

select * from table_name;

do(qlc:q([X||X <- mnesia:table(tableName)])).

使用qlc:q把查询编译成一种用于查询数据库的内部格式，最后给do去执行，返回结果。

#### 选择表里的字段数据

select field1, field2 from table_name;

do(qlc:q([X#table_name.filed1, X#table_name.filed2 || X <- mnesia:table(table_name)])),

#### 选择表里满足条件的数据

select field1 from table_name where filed2 > 250;

do(qlc:q([X#table_name.field1 || X <- mnesia:table(table_name),
                                 X#table_name.file2 > 250])).

### 添加和移除

#### 添加行

Row = #table{field1=Val1, field2=Val2},
F = fun() ->
            mnesia:write(Row)
    end,
mnesia:transaction(F).

#### 移除行

Row = {table, Field},
F = fun() ->
            mnesia:delete(Row)
    end,
mnesia:transaction(F).


### 事物 transaction

优点：
1 可以通过函数执行多条语句；
2 阻止并发访问数据库
优点：
1 可以通过函数执行多条语句；
2 阻止并发访问数据库
3 悲观锁定，防止同时操作产生异常。
4 载入模块中的数据，保存复杂数据
