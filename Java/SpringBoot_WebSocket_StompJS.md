---
title: Java - Spring web Socket + StompJS
date: 2020-01-15 18:00:26
tags:
    - java
    - web socket
    - stompJs
    - spring
category: 
    - java
---

# Code example Spring WebSocket 
## 1. Target
- Thử nghiệm websocket:
    - Từ server gửi payload tới client thông qua websocket. 
    - Từ client gửi payload tới topic
## 2. Stack
- Spring boot
- Sprint web socket
- Sockjs.js
- Stomp.js

## 3. Code
### 3.1 Configuration

```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig extends AbstractWebSocketMessageBrokerConfigurer {
    @Override
    public void registerStompEndpoints(StompEndpointRegistry stompEndpointRegistry) {
        stompEndpointRegistry.addEndpoint("/websocket-example")
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }
}
```
- `@EnableWebSocketMessageBroker` : enabled a broker-backed messaging over WebSocket using STOMP
- `registerStompEndpoints` : khai báo registerEndpoint, tất cả các socket client sẽ dùng url này để register, trước khi subscribe
- `configureMessageBroker` ...

### 3.2 @Controller

```java
@Controller
public class TestController {

    @Autowired
    SimpMessagingTemplate template;

    @RequestMapping("/test")
    public void sendAdhocMessages(@RequestParam("payload") String payload) {
        template.convertAndSend("/topic/001", payload);
    }

    @MessageMapping("/rm002")
    @SendTo("/topic/001")
    public String getUser(String payload) {
        return ("From rm002 " + payload);
    }
}
```
- ` @RequestMapping("/test")` : dùng để test từ server gửi payload tới client, thông qua RequestMapping
- `@MessageMapping("/rm002")` : khi client gửi message tới "mapping" này, thì message sẽ được redirect tới `/topic/001`. Tham khảo đoạn code js bên dưới để hiểu hơn.

### 3.3 Socket Client

```html
<!DOCTYPE html>
<html>
<head>
    <title>Hello WebSocket</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/sockjs-client/1.4.0/sockjs.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/2.3.3/stomp.js"></script>
</head>
<body>
test
</body>
</html>
<script>
    var SOCKET_URL_REGISTER = 'http://localhost:8091/websocket-example';
    var SOCKET_TOPIC_SUBSCRIBE = '/topic/001'
    var stompClient = null;
    $(document).ready(function () {
        var socket = new SockJS(SOCKET_URL_REGISTER);
        stompClient = Stomp.over(socket);
        stompClient.connect({"X-Token": "123"}, onConnected, onError);
    });

    function onConnected() {
        stompClient.subscribe(SOCKET_TOPIC_SUBSCRIBE, onMessageReceived);
    }

    function onMessageReceived(payload) {
        console.log(payload)
    }

    function onError(error) {
        console.log(error);
    }
    function sendMessage() {
        stompClient.send("/app/rm002", {}, "payload test 123");
    }
</script>
```

## 4. Demo
- Source code: https://github.com/tungtv202/spring-boot-websocket-example
- Sau khi build, truy cập vào url: http://localhost:8091/ , và F12 để theo dõi console
![1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/websocket/1.JPG)
- Để test case server gửi payload tới client đã subscribe, thực hiện truy cập url http://localhost:8091/test?payload=123  (tạo 1 cửa sổ web browser khác)
- Để test case client send message tới topic, gõ `sendMessage()` tại console F12 của web browser
