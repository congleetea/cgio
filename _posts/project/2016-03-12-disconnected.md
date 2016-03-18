 websocket 连接 emqttd 出现问题：
 
 开始没有问题，后面出现问题断开，但是自动重连可以连接上。
 
 ``````````
app.mqtt.js?_v=1.3.3:17 Uncaught Error: debug: AMQJS0008I Socket closed. app.mqtt.js?_v=1.3.3:17

onConnectionLostAccident @app.mqtt.js?_v=1.3.3:17
E._disconnected@app.mqtt.js?_v=1.3.3:17
E._on_socket_close@app.mqtt.js?_v=1.3.3:17
(anonymous function)@app.mqtt.js?_v=1.3.3:17

WebSocket connection to 'ws://192.168.0.77:11883/mqtt' failed: Connection closed before receiving a handshake response

app.mqtt.js?_v=1.3.3:17 Uncaught Error: error: AMQJS0007E Socket error:undefined.

app.mqtt.js?_v=1.3.3:17 WebSocket connection to 'ws://192.168.0.77:11883/mqtt' failed: Connection closed before receiving a handshake response
 ``````````
 
