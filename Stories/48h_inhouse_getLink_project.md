# Nhật ký làm hệ thống getLink vip Fshare trong 48h
Nhật ký ngày tháng năm...       
Vào một ngày đẹp trời, mình thấy các website cung cấp dịch vụ `getlink VIP fshare` đồng loạt thông báo lỗi, không thể getlink VIP download `maxbandwith`. Và mình cũng thấy rất nhiều bài viết mới được tạo trong 1 group (chuyên chia sẻ về IT), về việc sharing Fcode (fshare code) mà họ mới mua, và không dùng hết. Các `fcode` thì có hạn về số lượng, và thời gian sử dụng.   
Điều đó làm mình lóe lên suy nghĩ về việc tự làm 1 website getLink VIP. Và `Fshare` là dịch vụ mình sẽ thử nghiệm. 

// (Nếu có điều kiện, bạn hãy trả fee cho fshare để có thể sử dụng dịch vụ tốt hơn)

## 1. Ý tưởng thiết kế ban đầu
Fshare là 1 hệ thống cung cấp dịch vụ lưu trữ file nổi tiếng. Và để download file với tốc độ max băng thông, thì bạn cần có tài khoản VIP. Và để có tài khoản VIP thì bạn sẽ phải trả phí. Và theo `policy` của fshare thì 1 tài khoản VIP sẽ không bị giới hạn lượt tải, và băng thông tải.   
=> Mình sẽ làm 1 website mà client sẽ điền form chứa URL tới file cần download. Sau đó server backend sẽ sử dụng tài khoản VIP của mình, request fshare để lấy link download, rồi trả về cho client.    

- **Trở ngại 1...**   

Không thể làm như vậy được, vì fshare có cơ chế là chỉ địa chỉ IP nào request link download, thì chỉ địa chỉ IP đó mới có thể download được. Trong url download mà fshare trả về, đã được `signed` (link download có truyền thêm các parameter để validate), mình "đoán" một trong các param để signed, có `IP address` của client.     
=> Nếu việc request link không diễn ra ở backend service, thì mình sẽ làm nó ở frontend. 

- **Trở ngại 2...**     

Việc để client (frontend) tự động trực tiếp request link với fshare, làm mình lo lắng về việc bảo mật tài khoản VIP của mình. Mình không muốn client có được bất cứ thông tin gì nhạy cảm về tài khoản VIP. Hơn nữa, mình cũng đã thử nghiệm, khá phức tạp để `CORS` tới fshare (sử dụng `ajax` call chéo tới 1 domain khác domain đang chạy). Mình đã debug việc `cors` fshare bằng cách f12 của web browser. Và mình thấy fshare vẫn chấp nhận `cors`, nhưng nó quá phức tạp, khó control.    
=> Với 2 lý do trên, mình quyết định bỏ cách này. Và quay lại với cách đầu tiên. Get link ở phía backend server. Tuy nhiên, sau khi link download được tạo ra, trả cho client. Mình sẽ cung cấp luôn 1 đường proxy, có nhiệm vụ forward traffic download từ client tới server backend của mình, sau đó mới tới fshare. 

- **Trở ngại 3...**

Cách này cũng không hoàn hảo, vì việc forward traffic sẽ rất dễ gây `bottleneck` (nghẽn cổ chai) tại server của mình. Tuy nhiên server mà mình đang có, theo quảng cáo là bandwith lên tới 10Gbps. Mình không chắc chắn về performance khi số lượng client sử dụng lên nhiều, nhưng đó sẽ là 1 bài toán ở lĩnh vực khác. Nên mình vẫn quyết định triển theo hướng này.

## 2. Lựa chọn tech stack vòng 1
- Java vs Spring Framework (Springboot, Spring webservice...): java là ngôn ngữ mình dùng nhiều nhất, và Spring là 1 framework nổi tiếng. Nên mình dùng nó làm phía backend.
- Frontend: html + css + jquery + ajax. Mình sẽ dùng ajax để call api tới server backend.

## 3. Đi tìm cách kết nối với fshare
Mình đã google, nhưng không thấy fshare có 1 document nào nói về việc `public` API cho các developer.   
Mình lại bắt đầu suy nghĩ lại về việc debug f12 web browser `fshare.vn` để tìm format cho httpClient.       
Thật may mắn, sau đó mình search trên `github` thì lại thấy có repo về getLink fshare. 
Đó là repo này: https://github.com/tudoanh/get_fshare   (dùng python)    
Để chắc chắn API trong repo đúng, mình dùng phần mềm `PostMan` để test lại. Và kết quả các API vẫn tốt.     
Cơ bản có 2 API: 
1. Sử dụng `user_email` + `password` trên fshare, để lấy `session_id` và `token`
    - Request example:
    ```bash
    curl --location --request POST 'https://api.fshare.vn/api/user/login' \
    --header 'Content-Type: application/json' \
    --data-raw '{
                "user_email": "usename@gmail.com",
                "password": "passWord",
                "app_key": "L2S7R6ZMagggC5wWkQhX2+aDi467PPuftWUMRFSn"
            }
    '
    ```
    - Response example: 
    ```bash
    {
    "code": 200,
    "msg": "Login successfully!",
    "token": "483f5bb8ab3812070f95b2f52d0ff5645a4f4",
    "session_id": "f35jj7d0q5v91dt6b4r3vns"
    }
    ```

2. Sử dụng `token` để request link download
    - Request example:
    ```bash
    curl --location --request POST 'https://api.fshare.vn/api/session/download' \
    --header 'Content-Type: application/json' \
    --data-raw '{
                "token": "483f5bb8ab3812070f95b2f52d0ff5645a4f4",
                "url": "https://www.fshare.vn/file/VG8998AQNPB"
    }'
    ```
    - Response example:
    ```bash
    {
        "location": "http://download022.fshare.vn/dl/g1igLGM7IScOwdkwo3iwyPmJPDJk1roRViiVDbNszLZwk4k2xb-6TogmIK9Rjxq4y+Ggl2V0Z/ipz0g78hhb.wmv"
    }
    ```
// Các example trên mình export từ Postman. Mình đã dùng `Postman` thì thấy luôn ok. Nhưng không hiểu sao khi dùng `curl` lại lỗi. Khá khó hiểu. Hơn nữa, lại chỉ thấy sử dụng `token` chứ không thấy ở đâu sử dụng `session_id`. Về sau khi mình convert sang code Java, thì request thứ 2 luôn báo lỗi là "chưa đăng nhập". Sau đó mình phát hiện ra, trong request thứ 2, mình phải truyền thêm `header` chứa `Cookie`, trong đó giá trị `Cookie` có `session_id` thì mới pass.

## 4. Lựa chọn tech stack vòng 2
### 4.1 Lựa chọn
Việc dựng project `spring boot` có backend và frontend trong 1 repo khá nhanh. 
- Combo Spring framework
    - Để call tới API của fshare, cần 1 httpClient. Ban đầu mình định sử dụng `FeignClient`, code của nó khá ngắn. Tuy nhiên mình đã gặp khó khăn trong việc debug lỗi với fshare. Nên mình quyết định quay lại sử dụng `RestTemplate` của Spring. 
    - Ngay khi code `application` được run, mình cần phải lấy giá trị của `session_id`, `token` và lưu vào biến `static`. Mình sử dụng `CommandLineRunner`.
    - Mình phát hiện ra `session_id` + `token` chỉ sử dụng được trong 1 khoảng thời gian nhất định, có lẽ đây là chính sách của fshare. Vì vậy mình sử dụng thêm `Spring Scheduled` để hẹn giờ call API `rotation/ refresh` lại giá trị token + session_id mới. 
    - Việc client gửi form request lấy link download, và việc server request fshare, nên được chạy bất đồng bộ. Và vì bất đồng bộ, nên mình sử dụng `Spring Websocket` (spring-boot-starter-websocket) để làm 1 kênh gửi kết quả về cho client, sau khi Server run task lấy link download xong. Việc bất đồng bộ này cũng góp phần làm cho website của mình trở nên thân thiện hơn.
    - Mình sử dụng `ThreadPoolTaskExecutor/TaskExecutor` của Spring, để tạo task cho mỗi request get link. (chạy multi thread)

- Phía client, mình sử dụng `sockjs-client` + `stomp-websocket` để subscribe kênh socket. (subcribe để khi Server chạy task getlink xong, sẽ show kết quả ra phía frontend, mà không phải refresh page). Với mỗi phiên request client, mình sẽ sinh ra 1 topic socket mới. Mục đích để ID. Mình khá lo lắng về việc này sẽ dẫn tới performance của hệ thống giảm xuống nhiều.

### 4.2 Quick code
- Spring RestTemplate
```java
 public void setToken() {
        LoginRequest loginRequest = new LoginRequest();
        loginRequest.setUser_email(userMail);
        loginRequest.setPassword(password);
        loginRequest.setApp_key(appKey);
        RestTemplate restTemplate = new RestTemplate();
        LoginResponse loginResponse = restTemplate.postForObject(Const.FSHARE_ENDPOINT_LOGIN, loginRequest, LoginResponse.class);
        assert loginResponse != null;
        Const.FSHARE_SESSION_ID = loginResponse.getSession_id();
        Const.FSHARE_TOKEN = loginResponse.getToken();
    }
```
- CommandLineRunner
```java
@Component
public class GetToken implements CommandLineRunner {
    @Autowired
    private FshareService fshareService;

    @Override
    public void run(String... strings) {
        fshareService.setToken();
    }
}
```
- Spring Scheduled
```java
@Component
public class RefreshToken {
    @Autowired
    private FshareService fshareService;

    @Scheduled(fixedRate = 1000 * 60 * 60 * 2)
    public void run() {
        fshareService.setToken();
    }
}
```
- Spring Websocket
```java
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig extends AbstractWebSocketMessageBrokerConfigurer {
    @Override
    public void registerStompEndpoints(StompEndpointRegistry stompEndpointRegistry) {
        stompEndpointRegistry.addEndpoint("/websocket-receive-link")
                .withSockJS();
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }
}
```

- ThreadPoolTaskExecutor
```java
    @Bean
    @Primary
    TaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor t = new ThreadPoolTaskExecutor();
        t.setCorePoolSize(10);
        t.setMaxPoolSize(100);
        t.setQueueCapacity(500);
        return t;
    }
    
    //
    @Autowired
    private TaskExecutor task;

    //
    task.execute(new TaskGetLink(requestLink, template, fshareService));
```

- sockjs-client + stomp-websocket
```js
function initSocket() {
    var socket = new SockJS('/websocket-receive-link');
    stompClient = Stomp.over(socket);
    stompClient.connect({"X-Token": "tokenvalue"}, onConnected, onError);

    function onConnected() {
        stompClient.subscribe("/topic/" + requestId, onMessageReceived);
    }

    function onMessageReceived(payload) {
        // todo some thing
    }

    function onError(error) {
         // todo some thing
    }
}
```

## 5. Trở ngại 4
Việc code application về cơ bản đã hoàn thiện kha khá. Mình bắt đầu tìm solution cho việc `proxy traffic` mà mình đã nhắc bên trên. Traffic download sẽ từ client rồi forward qua server của mình, sau đó mới tới fshare. 
Mình đã google rất nhiều về cách này, nhưng khá là rối với skill hiện tại.    
Trong lúc trầm tư suy ngẫm, mình sực nhớ ra `NGINX`, 1 thằng mà mình từng dùng, có thể làm được điều này, 1 điều mà mình lại quên béng mất.     
=> Ý tưởng:     
Nôm na thì linkdownload của fshare trả về đại loại format sau
```
http://download022.fshare.vn/dl/g1igLGM7IScOwdkwo3iwyPmJPDJk1roRViimGIL8t7VDbNxb-6TogmIK9Rjxq4y+Ggl2V0Z/ipz0g78hhb.wmv
```
Trong đó `download022.fshare.vn` chính là server fshare. Bây giờ mình sẽ biến nó thành `download022.tungexplorer.me` - là địa chỉ server của mình. Và link downoad cho client là:
```
http://download022.tungexplorer.me/dl/g1igLGM7IScOwdkwo3iwyPmJPDJk1roRViimGIL8t7VDbNxb-6TogmIK9Rjxq4y+Ggl2V0Z/ipz0g78hhb.wmv
```
- Việc replace chuỗi String này trong java chỉ 1 nốt nhạc. 
- Cấu hình `Nginx` tham khảo:
```bash
server {
  listen 80;
  server_name download03333.tungexplorer.me;
  access_log off;

  location / {
    proxy_pass http://download022.fshare.vn;
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_redirect     off;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;
  }
}
```

## 6. Trở ngại 5
Mình phát hiện ra `endpoint` mà fshare cung cấp, không chỉ có `download022.fshare.vn`, mà nó loadbalancer qua nhiều endpoint khác nữa. Ví dụ 023, 024, 011...
Mình không thể config 1 cách bị động cho từng endpoint như vậy được.    
=> Config với `regex` để dynamic việc route proxy. 
Việc này khiến mình mất khá nhiều thời gian, vì mình không quá thành thục về việc này. Nó làm mình mất 3-4 tiếng để thử nghiệm regex, và google debug.      
Cuối cùng format hoạt động tốt:
```bash
server {
  listen 80;
  server_name   ~^(www\.)?[^.]+.tungexplorer.me$;
  access_log off;
  if ($host ~* ^(www\.)?([^.]+).tungexplorer.me$) {
    set $subdomain $2;
  }
  resolver 8.8.8.8 valid=10s;
  location / {
    proxy_pass http://$subdomain.fshare.vn;
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_redirect     off;

    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;
  }
}
```

## 7. Lựa chọn tech stack vòng 3
Về cơ bản hệ thống đã hoạt động gần như ý mình muốn. Tuy nhiên mình muốn làm 2 việc nữa:
1. Control limit bandwith cho mỗi lượt download. Tuy server mình có đường truyền tới 10Gbps, tuy nhiên mình muốn mỗi lượt download, chỉ có tốc độ giới hạn là XXX `Mbps`. => NGINX Plus cung cấp tính năng này, tuy nhiên giá Nginx Plus khá đắt. $25000 / năm. => tới thời điểm hiện tại mình vẫn bỏ ngỏ bài toán này.
2. Mình cần 1 hệ thống monitor webserver của mình, mình muốn theo dõi là hiện tại đang có bao nhiêu lượt download, tổng traffic trên các cổng mạng đang là bao nhiêu, tài nguyên cpu, ram có đang full load không. Sau khi cân nhắc mình quyết định sử dụng combo: `Prometheus + Grafana + Prometheus Exporter`
    - Prometheus server: lấy metric từ các `client/ device` về để theo dõi.
    - Prometheus Exporter : client của prometheus, thu thập metric trên "client" đang chạy, để gửi về cho `prometheus server`
    - Grafana: kết nối với prometheus, sau đó đồ thị hóa việc show metric cho admin, thông qua webUI. 

Hình ảnh chụp `1 Dashboard monitor traffic của Grafana`
![Grafana](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/grafana/snmp_garafana.png)

Note: việc sử dụng combo `Prometheus + Grafana + Prometheus Exporter` mới đầu mình đánh giá có vẻ khá thừa thãi, thấy khá "phức tạp hóa" vấn đề. Tuy nhiên, hệ thống này mình sẽ còn phát triển thêm nữa. Nên mình vẫn quyết định lựa chọn dùng chúng.

## 8. Full SourceCode
- Mình public source application tại đây: https://github.com/tungtv202/getlink_fshare
