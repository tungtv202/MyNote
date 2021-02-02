---
title: Reactive Programming - Reactor - DEMO 001
date: 2021-01-23 16:00:26
tags:
    - java
    - reactive
    - reactor
    - spring webflux
    - webclient
category: 
    - java
---
# DEMO CODE - PROJECT REACTOR
## Technical 
- Java 11, Maven, Lombok
- Spring boot, Spring WebFlux: for reactive web
    - Webclient: reactive client to perform HTTP requests, non-blocking
- Project Reactor: for reactive programming
    - BlockHound: Java agent to detect blocking calls from non-blocking threads.
- Jackson: JSON serialization/deserialization library

## Đề bài
Xây dựng api backend cho 1 hệ thống e-commerce, api có nhiệm vụ lấy ra danh sách `Popular purchases` theo `username`.   
Cơ chế như sau:
- Lấy ra 5 giao dịch gần nhất, bằng cách call api tới 3rd `GET /api/purchases/by_user/:username?limit=5`.  
Example: `GET /api/purchases/by_user/Jasen64`   
  Response:   


```json
{
  "purchases": [
    {
      "id": 598185,
      "username": "Jasen64",
      "productId": 996330,
      "date": "2020-11-11T12:16:15.635Z"
    },
    {
      "id": 719912,
      "username": "Jasen64",
      "productId": 17423,
      "date": "2020-11-16T19:31:38.636Z"
    },
    {
      "id": 179878,
      "username": "Jasen64",
      "productId": 653043,
      "date": "2020-11-16T23:26:20.636Z"
    }
  ]
}
```


- Với mỗi sản phẩm, lấy ra danh sách tất cả những người đã mua sản phẩm đấy, bằng cách call api tới `GET /api/purchases/by_product/:product_id`.    
Example: `GET /api/purchases/by_product/996330` 
  Response:


```json
  {
  "purchases": [
    {
      "id": 598185,
      "username": "Jasen64",
      "productId": 996330,
      "date": "2020-11-11T12:16:15.635Z"
    },
    {
      "id": 128524,
      "username": "Gregg_Rowe34",
      "productId": 996330,
      "date": "2020-11-21T01:48:24.637Z"
    },
    {
      "id": 494415,
      "username": "Gregg_Rowe34",
      "productId": 996330,
      "date": "2020-11-16T23:14:56.637Z"
    }
  ]
}  
```


- Cùng thời điểm, lấy ra danh sách thông tin về Sản phẩm, bằng cách call api tới `GET /api/products/:product_id`.   
Example: `GET /api/products/996330` 
  Response: 


```json
{
    "product": {
        "id": 996330,
        "face": "(ᵒ̤̑ ₀̑ ᵒ̤̑)",
        "price": 1165,
        "size": 23
    }
}
```
- Kết quả của api lấy thông tin `Popular Purchase` format như sau:

```json
[
  {
    "id": 555622,
    "face": " 。◕‿◕。 ",
    "price": 1100,
    "size": 27,
    "recent": [
      "Frannie79",
      "Barney_Bins18",
      "Hortense6",
      "Melvina84"
    ]
  },
  ...
]
```

- Dữ liệu của `Popular Purchase` phải được cache
- Dữ liệu của `Popular Purchase` phải được sắp xếp theo product có số lượng người mua nhiều nhất lên đầu.
## Step by step
### First round
1. Webclient
- Để call tới hệ thống 3rd qua api, cần 1 http client. Trong Spring 5, có hỗ trợ reactive web client là `Webclient`. 
Nó hỗ trợ function programming, syntax khá tiện, tiện như `openFeign client` trong spring cloud.   


```java
@Slf4j
@Configuration
public class ClientConfig {

    // base url của hệ thống 3rd
    @Value("${client.base_url}")
    private String baseUrl;

    @Bean
    @Primary
    public WebClient webClient() {
        var strategies = ExchangeStrategies.builder()
                .codecs(clientCodecConfigurer -> {
                    clientCodecConfigurer.defaultCodecs().jackson2JsonDecoder(new CustomizeJsonDecoder(objectMapper(), MediaType.APPLICATION_JSON));
                })
                .build();
        return WebClient.builder()
                .exchangeStrategies(strategies)
                .baseUrl(baseUrl)
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    // Sử dụng jackson để deserialize 
    private ObjectMapper objectMapper() {
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.UNWRAP_ROOT_VALUE, true);
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        return objectMapper;
    }
}
```     



```java
@Slf4j
@Component
public class UserClient {
    @Autowired
    private WebClient webClient;

    public Mono<User> get(String username) {
        return webClient.get()
                .uri("users/{username}", username)
                .retrieve()
                .bodyToMono(User.class)
                .doOnError(e -> log.error(e.getMessage()));
    }
}


@Slf4j
@Component
public class ProductClient {
    @Autowired
    private WebClient webClient;

    public Mono<Product> get(int id) {
        log.info("Start get productId={}", id);
        return webClient.get()
                .uri("products/{id}", id)
                .retrieve()
                .bodyToMono(Product.class)
                .doOnNext(e -> log.info("Product id={}, data={}", id, e))
                .delayElement(Duration.ofMillis(500))
                .doOnError(e -> log.error(e.getMessage()));
    }
}

@Component
@Slf4j
public class PurchaseClient {
    @Autowired
    private WebClient webClient;

    public Mono<PurchaseList> listByUsername(String username, int limit) {
        log.info("Start listByUsername, username={}", username);
        return webClient.get()
                .uri(uriBuilder -> uriBuilder.path("purchases/by_user/" + username)
                        .queryParam("limit", limit)
                        .build())
                .retrieve()
                .bodyToMono(PurchaseList.class)
                .doOnNext(e -> log.info("PurchaseList username={}, data={}", username, e))
                .delayElement(Duration.ofMillis(1000))
                .doOnError(e -> log.error(e.getMessage()));
    }

    public Mono<PurchaseList> listByProductId(int productId, int limit) {
        log.info("Start listByProductId, id={}", productId);
        return webClient.get()
                .uri(uriBuilder -> uriBuilder.path("purchases/by_product/" + productId)
                        .queryParam("limit", limit).build())
                .retrieve()
                .bodyToMono(PurchaseList.class)
                .doOnNext(e -> log.info("listByProductId productId={}, data={}", productId, e))
                .delayElement(Duration.ofMillis(600))
                .doOnError(e -> log.error(e.getMessage()));
    }
}
```     


- Sử dụng `doOnNext` để xem log
- Sử dụng `delayElement` để giả lập thời gian mà api 3rd trả về. 

2. LocalCacheServiceImpl
- Cache trực tiếp trên localmem   


```java
    public static final int MAX_AGE = 30000;
    public static Map<String, CacheValue> INMEMORY_DATABASE = new ConcurrentHashMap<>();

    @Override
    public List<PopularPurchasesDto> getPopularPurchases(String username) {
        log.info("getPopularPurchases , username={}", username);
        if (ObjectUtils.isEmpty(username)) return null;
        var cacheValue = INMEMORY_DATABASE.get(username);
        return cacheValue == null ? null : (System.currentTimeMillis() - cacheValue.getCommittedTime() > MAX_AGE
                ? null : cacheValue.getPopularPurchasesDto());
    }

    @Override
    public void setPopularPurchases(String username, Flux<PopularPurchasesDto> value) {
        List<PopularPurchasesDto> cacheValue = new ArrayList<>();
        value.collectList().map(cacheValue::addAll).subscribe();
        INMEMORY_DATABASE.put(username, new CacheValue(cacheValue));
    }

    @Override
    public void setPopularPurchases(String username, List<PopularPurchasesDto> value) {
        log.info("setPopularPurchases, username={}", username);
        INMEMORY_DATABASE.put(username, new CacheValue(value));
    }
``` 

- evict manual (có thể sử dụng Caffein Cache hoặc Redis, để cache auto evict, nếu muốn làm phức tạp hơn)

3. Route Controller
- Spring web Flux hỗ trợ việc khai báo các controller kiểu `HandlerFunction and RouterFunctions`  


```java
 @Bean
    RouterFunction<ServerResponse> routes(PurchaseHandler handler) {
        return route(GET("/api/recent_purchases/{username}"), handler::purchasesRecent);
    }
```

4. Core logic


```java
    public Mono<ServerResponse> purchasesRecent(ServerRequest request) {
        final var username = request.pathVariable("username");
        return userClient.get(username)
                .flatMap(c -> ok().contentType(MediaType.APPLICATION_JSON)
                        .body(getPopularPurchasesDto(username), PopularPurchasesDto.class))
                .switchIfEmpty(ServerResponse.status(HttpStatus.NOT_FOUND)
                        .bodyValue(String.format("User with username of %s  was not found", username)));
    }

    private Flux<PopularPurchasesDto> getPopularPurchasesDto(String username) {
        var cacheValue = cacheService.getPopularPurchases(username);
        if (cacheValue != null) return Flux.fromIterable(cacheValue);
        var productFlux = purchaseClient.listByUsername(username, PURCHASES_RECENT_LIMIT)
                .flatMapMany(Flux::fromIterable)
                .flatMap(e -> productClient.get(e.getProductId()));
        var popularPurchasesDtoFlux = productFlux.flatMap(e ->
                purchaseClient.listByProductId(e.getId(), Integer.MAX_VALUE)
                        .map(r -> new PopularPurchasesDto(e, r)));
        // sort
        var result = popularPurchasesDtoFlux.collectSortedList((a, b) ->
                a.getRecentUsername().size() > b.getRecentUsername().size() ? -1 : 0)
                .flatMapMany(Flux::fromIterable);
        cacheService.setPopularPurchases(username, result);
        return result;
    }
```

- Ý đồ code: sau khi lấy ra được danh sách 5 giao dịch gần nhất. Thì các api lấy danh sách user đã mua theo sản phẩm, và api lấy thông tin sản phẩm, có thể được call 1 cách song song, độc lập, đồng thời, để giảm tổng thời gian truy vấn.
- Flow: get value từ cache -> có thì trả về, không có thì call từ api tới 3rd, tính toán ra DTO -> lưu vào cache -> trả về.

### Phát hiện các vấn đề và cải tiến
1. Use `zip`
![Should Use Zip](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/shouldUseZip.JPG)
- Các api lấy thông tin sản phẩm, và api lấy danh sách người mua theo sản phẩm, được chạy ở các thread khác nhau (`ctor-http-nio-4`, `ctor-http-nio-5`, `parallel-4`, `parallel-1` ) => có vẻ đã chạy đúng ý đồ, none-blocking
- Nhưng các `PurchaseClient` chỉ được run, khi các `ProductClient` đã done. Thực tế thì có thể triển khai 2 client này `run` cùng lúc. 
- Chuyền `double flatMap` => `zip`

```java
    private Mono<List<PopularPurchasesDto>> getPopularPurchasesWithoutCache(String username) {
        log.info("getPopularPurchasesWithoutCache - username: {}", username);
        return purchaseClient.listByUsername(username, PURCHASES_RECENT_LIMIT)
                .flatMapMany(Flux::fromIterable)
                .flatMap(e -> Flux.zip(productClient.get(e.getProductId()),
                        purchaseClient.listByProductId(e.getProductId(), Integer.MAX_VALUE)))
                .map(e -> new PopularPurchasesDto(e.getT1(), e.getT2()))
                .collectSortedList((a, b) ->
                        a.getRecentUsername().size() > b.getRecentUsername().size() ? -1 : 0);
    }
```
- Kết quả `PurchaseClient` và  `ProductClient` run prallel
![Should Use ZIp Result](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/shoudUseZipResult.JPG)

2. Cold publisher problem
- Old code:

```java
   public void setPopularPurchases(String username, Flux<PopularPurchasesDto> value) {
        List<PopularPurchasesDto> cacheValue = new ArrayList<>();
        value.collectList().map(cacheValue::addAll).subscribe();
        INMEMORY_DATABASE.put(username, new CacheValue(cacheValue));
    }
```
- Việc truyền vào 1 `Flux<PopularPurchasesDto>`, và Flux đang mặc định là `cold publisher`, sau đó thực hiện `.subscribe()` khiến cho toàn bộ các api được call lại 1 lần nữa. => BAD
- New Cold: nhét method `setPopularPurchases` vào trong `doOnNext` của `publisher`


```java
    private Flux<PopularPurchasesDto> getPopularPurchasesDto3(String username) {
        var cacheValue = cacheService.getPopularPurchasesAsync(username)
                .switchIfEmpty(getPopularPurchasesWithoutCache(username)
                        .doOnSuccess(e -> cacheService.setPopularPurchases(username, e)));
        return cacheValue.flatMapMany(Flux::fromIterable);
    }
```

3. Something keep `blocking`
- Theo 1 số blog chia sẻ trên mạng, thì method `getPopularPurchases(String username)` hiện tại có thể dẫn tới blocking (mình chưa tái hiện được). => giải pháp thay thế:
```java
    @Override
    public Mono<List<PopularPurchasesDto>> getPopularPurchasesAsync(String username) {
        return Mono.fromCompletionStage(CompletableFuture.supplyAsync(() -> getPopularPurchases(username)));
    }
```

- Sử dụng `blockhood` để phát hiện blocking
```xml
<dependency>
  <groupId>io.projectreactor.tools</groupId>
  <artifactId>blockhound</artifactId>
  <version>1.0.4.RELEASE</version>
</dependency>
```
- Install blockhound

```java
    public static void main(String[] args) {
        BlockHound.install();
        SpringApplication.run(ReactorApplication.class, args);
    }
```
- Test khi call api 3rd, và thấy bị `blocking` => Có vẻ như server 3rd, không hỗ trợ việc reactive
![Blocking by 3rd](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/BlockingBy3rd.JPG)

## How to run source code?
1. Maven clean & package   
 
```./mvnw clean package```
2. Change config file
    - `src/main/resources/application.properties`
        - Change api base_url (nodejs server, that run at `daw-purchases-master`)
        - Change port web server (default is 8080)
    
3. Run spring-boot 
```./mvnw spring-boot:run ```
4. Test api - get recent purchases 

```bash
curl --request GET 'http://127.0.0.1:8080/api/recent_purchases/Jasen64' 
```

## Conclusion
- Bài lap forcus vào `reactive` nên sẽ `do it` mọi nơi có thể. Nhưng thực tế nhiều chỗ đang sử dụng nó 1 cách không hiệu quả.
  - Các api của 3rd không hỗ trợ reactive
  - Danh sách `Popular purchase` mà hệ thống query và trả về cho client thông qua api `/api/recent_purchases/{user}`, không cần stream, bởi kết quả là 1 danh sách, yêu cầu phải được `sort`. Việc sort này được thực hiện khi toàn bộ List DTO đã DONE.


- Sourcecode: https://github.com/tungtv202/reactor_flux_001
