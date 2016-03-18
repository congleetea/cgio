---
layout: post
title: Way To Program
category: opinion
description: 在编程的路上，发现自己的不足，寻找一些思路。 
---
    1 出现问题要尝试着去寻找原因，很多问题可以通过打印log信息来寻找。
    2 erlang中的匹配是很多问题出现的原因，很多输出结果是又后面会附带ok，error等的元组构成的，我们要使用相应的匹配法则去提取出有用的东西。如果lager无法打印出调试信息，那么可以在相应的地方看看会不会是出现了匹配问题。
    3 erlang中的配置文件在移动复制之后一定要注意每一项末尾的逗号，最后一项要去掉。程序中每个函数最后一个则要以句号结尾。
    4 怎么控制lager的打印，在配置文件中:         {lager_console_backend, info}, <!-- 打印info及以上级别 -->
 {lager, [
    {colored, true},
    {async_threshold, 5000},
    {error_logger_redirect, false},
    {crash_log, "log/emqttd_crash.log"},
    {handlers, [
        {lager_console_backend, info}, <!-- 打印info及以上级别 -->
        %%NOTICE: Level >= error
        %%{lager_emqtt_backend, error},
        {lager_file_backend, [
            {formatter_config, [time, " ", pid, " [",severity,"] ", message, "\n"]},
            {file, "log/emqttd_error.log"},
            {level, error},
            {size, 104857600},
            {date, "$D0"},
            {count, 30}
        ]}
    ]}
 ]},


[congleetea]:    https://congleetea.github.io  "congleetea"
