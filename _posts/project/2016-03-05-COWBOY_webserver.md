---
layout: post
title: 使用cowboy来搭建服务器 
category: project 
description: 使用rebar构建基于cowboy的简单网络服务器
---

## 建立工程

使用rebar来建立框架：

$ mkdir webser

$ cd webserver

$ cp rebar to this dir

$ ./rebar create-app appid=webserver
``````````````````
==> webserver (create-app)
Writing src/webserver.app.src
Writing src/webserver_app.erl
Writing src/webserver_sup.erl


``````````````````
$ ./rebar compile
``````````````````````
==> webserver (compile)
Compiled src/webserver_app.erl
Compiled src/webserver_sup.erl


``````````````````````
$ mkdir rel

$ cd rel

$ ../rebar create-node nodeid=webserver 
```````````````````

==> rel (create-node)
Writing reltool.config
Writing files/erl
Writing files/nodetool
Writing files/webserver
Writing files/sys.config
Writing files/vm.args
Writing files/webserver.cmd
Writing files/start_erl.cmd
Writing files/install_upgrade.escript


```````````````````

修改文件files/reltool.config:
       {lib_dirs, ["../..", "../deps"]}, %% 如果有deps才加上，没有就不加

在根目录下面建立deps文件。

$ ../rebar generate

==> rel (generate)
到此工程就建立起来了，为了方便，我们使用makefile来做一些事：
建立makefile文件：

```````````

ERL=erl
BEAMDIR=./deps/*/ebin ./ebin
BASE_DIR=$(shell pwd)
REBAR = $(BASE_DIR)/rebar

all: clean get-deps rel

get-deps:
	@$(REBAR) get-deps

compile:
	@$(REBAR) compile

clean:
	@$(REBAR) clean

rel: compile
	@cd rel && $(REBAR) generate -f


```````````
建立依赖项rebar.config
`````````````````````
{deps_dir, "deps"}.
{deps, [
        {cowboy, ".*", {git, "https://github.com/ninenines/cowboy", "1.0.0"}}
       ]}.


`````````````````````
最后编译整个工程：
$ make all
$ ./rel/webserver/bin/webserver console



## 构建服务器

1  在 webserver.app.src 中applications中加入依赖项cowboy,使他能被启动。
``````````````````

{application, webserver,
 [
  {description, ""},
  {vsn, "1"},
  {registered, []},
  {applications, [
                  kernel,
                  stdlib,
                  cowboy
                 ]},
  {mod, { webserver_app, []}},
  {env, []}
 ]}.

``````````````````
2 在webserver_app.erl
``````````````


-module(webserver_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Routes = routes(),
    Dispatch = cowboy_router:compile(Routes),
    TransOpts = [{port, 8080}],
    ProtOpts = [{env, [{dispatch, Dispatch}]}],
    cowboy:start_http(http, 100, TransOpts, ProtOpts),

    webserver_sup:start_link().

stop(_State) ->
    ok.

routes() ->
    %% a host is for a list
    [
     %% Host1
     {'_',                                      % HostMatch
      [                                         % PathsList
        {"/", web_handler, []}              % Path1={PathMatch, Handler, Opts} or {PathMatch, Constraints, Handler, Opts} 
    ]}].

``````````````
使用路由将路径和handleer模块绑定起来，这样他就会到web_handler模块中去执行了。

3 新建handler模块： web_handler.erl 
```````````````

-module(web_handler).
-behaviour(cowboy_http_handler).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

-record(state, {
         }).

init(_, Req, _Opts) ->
    {ok, Req, #state{}}.

handle(Req, State=#state{}) ->
    {ok, Req2} = cowboy_req:reply(200,
                                  [{<<"content-type">>, <<"text/plain">>}],
                                  <<"Hello web!">>,
                                  Req),
    {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
    ok.

```````````````
当出现请求的时候，会转到对应的handler模块执行，这个模块一定有单个部分：init/3, handle/2, terminate/3。首先执行init初始化函数，然后把相应的参数带到handle中执行。
**注意**, 我们在使用的时候，像下面这个样子会出错：
````````````

-record(state, {
         }).

init(_, Req, _Opts) ->
    {ok, Req2} = cowboy_req:reply(200,
                                  [{<<"content-type">>, <<"text/plain">>}],
                                  <<"Hello web!">>,
                                  Req),
    {ok, Req2, #state{}}.

handle(Req, State=#state{}) ->
    {ok, Req2} = cowboy_req:reply(200,
                                  [{<<"content-type">>, <<"text/plain">>}],
                                  <<"Hello web!">>,
                                  Req),
    {ok, Req2, State}.

terminate(_Reason, _Req, _State) ->
    ok.

````````````
不能两个地方都reply，在init中最好就做一些参数方面的工作。

## 运行
make all编译之后，在浏览器中输入： http://localhost:8080/ 就可以得到hello web的字样了，这就是简单的使用rebar和cowboy来做的一个web服务器。

