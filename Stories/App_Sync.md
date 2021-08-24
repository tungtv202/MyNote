---
title: Nhật ký cải tiến / xây mới ứng dụng Sync Data (via Rest API)
date: 2021-01-10 10:39:26
updated: 2021-01-10 10:39:26
tags:
    - sync
category: 
    - stories
---
# Bài toán
- Xây dựng ứng dụng phục vụ việc đồng bộ dữ liệu giữa 2 hệ thống (thông qua call API)
- Đối tượng cần đồng đồng bộ: dữ liệu của khách hàng (ví dụ thông tin sản phẩm, đơn hàng...)
- Đồng bộ tự động khi 2 bên có thay đổi dữ liệu 
- Đồng bộ thủ công khi có request đồng bộ từ user

# Hệ thống cũ đang có
## Cơ chế
![OldArt](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/app_sync/OldArt.JPG)
- `Sync App` đăng ký webhook với 2 hệ thống `A` và `B`. Khi thông tin sản phẩm trên 2 hệ thống A và B có thay đổi, 2 hệ thống A và B sẽ call webhook tới địa chỉ `Sync App` đăng ký
- `I` là 1 application gateway, nhận webhook từ A và B. `I` cần đảm bảo tính Available cực cao.
- `I` nhận webhook, gửi message vào Kafka. Với mỗi `type` đồng bộ, sẽ có 1 topic khác nhau.
- `Sync App` consumer message từ Kafka và thực hiện nghiệp vụ đồng bộ bằng cách lấy thông tin mới nhất từ `source`, kết hợp với thông tin được lưu trong database, sau đó tạo ra model (body) để call api sang `dest`

## Các vấn đề
### Vấn đề chủ quan
- code cũ rất khó maintaince. Không handler được các error, không phân tách được nghiệp vụ đúng của đồng bộ tự động, và thủ công. 
### Vấn để khách quan
- Khi hệ thống A hoặc B rơi vào cao điểm, số lượng webhook được call tới I rất nhiều. Vì call qua api, nên có thể khi request được nhận tại I không còn đảm bảo được đúng thứ tự => sai lệch đồng bộ.
- `Sync App` lấy message từ Kafka để trigger đồng bộ. Nhưng không thể scale được, vì phụ thuộc vào số partition của Kafka, dẫn tới msg có thể bị lag rất nhiều nếu peak.
- Cơ chế retry khi call api từ `Sync App` sang A,B bị lỗi hoạt động không hiệu quả. (bị ignore, hoặc retry không đúng thời điểm mình muốn retry)

## Vấn đề cần suy nghĩ khi quyết định code lại app
- Làm thế nào để Sync App nhận được message báo có sự thay đổi dữ liệu từ 2 hệ thống, nhưng phải đảm bảo đúng thứ tự?
- Làm thế nào để lọc các message bị trùng lặp. (khi lỗi hệ thống, hoặc khi hệ thống `Sync App` thực hiện call api đồng bộ sang A, nhưng ngay sau đó A lại gửi lại message thay đổi data ngược lại `Sync App` ?) điều này tiềm ẩn nguy cơ loop.
- Làm thế nào để scale được worker tùy ý?
- Làm thế nào để chủ động retry việc đồng bộ khi  có lỗi hệ thống A, B?

# Hệ thống mới
## Cơ chế
![Hệ thống mới](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/app_sync/NewArt.JPG)
- Không sử dụng cơ chế nghe webhook khi có data thay đổi. (bỏ hệ thống `I`). => Consum trực tiếp từ Kafka nội bộ của A và B. 
- Việc sync data từ `SyncApp` tới A và B vẫn sử dụng call Rest API như cũ.
- Khi nhận được msg kafka báo có dữ liệu thay đổi. Sync App sẽ filter và lưu vào database. Sau đó 1 task vụ khác sẽ query từ database ra để xử lý. (Database được sử dụng nhiều hơn. Sử dụng database Sql Server như 1 queue.)
## Giải quyết các vấn đề
- Đảm bảo thứ tự dữ liệu thay đổi?
    > Đảm bảo tuyệt đối tính thứ tự của mỗi topic A hoặc B. Tức là khi thay đổi dữ liệu bên A thì msg gửi đi luôn đảm bảo thứ tự đúng khi nhận được `Sync App`. 

    > Đảm bảo tương đối tính thứ tự với 2 hệ thống A và B. Tức là với 1 sản phẩm X có trên cả A và B. Và X có sự thay đổi ở cả A và B. Thực tế X được thay đổi trên A trước. Nhưng có thể Kafka A bị lag, dẫn tới thay đổi trên B diễn ra sau, nhưng  `Sync App` lại nhận được trước. Case này % rất thấp????
- Khi consum msg Kafka A và Kafka B, sẽ có rất nhiều msg không thuộc phạm vi của `Sync App`, làm thể nào để filter nó 1 cách nhanh nhất có thể?
    > Toàn bộ danh sách storeId thuộc phạm vi quản lý của SynApp sẽ được chứa trong 1 HashSet. Sử dụng HashSet này để filter cho performance nhanh nhất. HashSet này sẽ được load khi startUp app, và cập nhật định kỳ + cập nhật ngay lập tức khi có handler. 
- Làm thế nào để scale worker tùy ý?
    > Sử dụng table trong database như 1 queue.
- Table `SynRequests` (table core)
```sql
create table SyncRequests
(
    Id             int identity
        constraint SyncRequests_pk
            primary key,
    StoreId        int                        not null,
    SyncType       nvarchar(100)              not null,
    SyncAction     nvarchar(100),
    Target         nvarchar(100),
    ObjectId       int                        not null,
    SubObjectId    int,
    Origin         nvarchar(50),
    ProgressStatus nvarchar(100)              not null,
    FireCounter    int,
    Payload        nvarchar(max),
    CreatedOn      datetime default getdate() not null,
    Error          nvarchar(max),
    PrevFireTime   datetime,
    ForceSync      bit
)
```
    - SyncType: enum, quy định type sync, ví dụ: product_a_to_b, product_b_to_a ...
    - SyncAction: enum, quy định action sync, ví dụ: deleted, update
    - Target: enum, quy định đối tượng sync, ví dụ: product, order, inventory
    - ObjectId, SubObjectId: lưu trữ thông tin Id của product, order...
    - Origin: enum, quy định nguồn gốc của lệnh sync: auto, manual, system
    - ProgressStatus: enum. Trạng thái của lệnh sync. Waiting, processing, fail, success. Khi đang ở trạng thái `processing` thì worker sẽ filter, không xử lý. Khi success thì sẽ bị xóa bản ghi này đi. Khi fail, thì sẽ bị giữ lại. Sẽ có 1 job schedule scan định kỳ set trạng thái từ fail -> waiting
    - FireCounter: số lần lệnh sync được chạy, bình thường nếu sync thành công fireCounter = 0, tuy nhiên nếu fail thì fireCounter sẽ được tăng dần lên. Và khi tới ngưỡng, mà vẫn fail, thì sẽ bị loại bỏ khỏi table.
    - Payload: chứa dữ liệu trong msg được gửi từ A , B
    - Error: lưu lại message lỗi khi đồng bộ 
    - PrevFireTime: thời gian của lần sync gần nhất. 
    - ForceSync: flag, hỗ trợ nghiệp vụ sync, trong trường hợp maintaince.

## Start
- Như mọi khi, chuyển đổi toàn bộ Spring RestTemplate sang dùng OpenFeign Client. Rất thuận tiện cho việc call api từ SyncApp tới A, B.
    - Sửa lại config Feign, handler ở `Decode` để log lại toàn bộ api đã được call từ `SyncApp` sang A và B. (method != GET)
    - Sử dụng thêm header `accept gzip` để tăng performance call api. Nhưng không đạt hiệu quả, vì các api của A, B không đồng nhất header. 
- Chuyển sang dùng `enum` ở bất kỳ chỗ nào có thể.
- Sử dụng JPA thay cho JDBC thuần
- Tất cả các model, khuyến khích sử dụng @Builder tối đa. Nhằm tránh việc sử dụng style code Setter, khó tracking code khi bị mutable.
- `StoreContext` model core dự án. Ngoài chứa thông tin store, sẽ chứa toàn bộ thông tin cấu hình đồng bộ. Vì được sử dụng cực kỳ nhiều, nên sẽ được local cache. Và sẽ refresh mỗi khi có 1 sync request mới
- Lưu ý: code cần handler việc khi app startup xong 1 time, load xong toàn bộ danh sách storeId từ db vào HashSet xong, thì mới trigger bật kafka consumer.
```java
public class InitInMemoryDbTask {
    @Autowired
    private CacheService cacheService;

    @Autowired
    private KafkaListenerEndpointRegistry kafkaListenerContainerFactory;

    @Scheduled(fixedRate = 10000)
    void initAllPosTenantIdAndWebStoreId() {
        cacheService.initAllPosTenantId();
        cacheService.initAllWebStoreId();
        if (!Constants.KAFKA_IS_RUNNING) {
            kafkaListenerContainerFactory.getAllListenerContainers().forEach(e -> {
                if (!e.isRunning()) {
                    e.start();
                }
            });
            Constants.KAFKA_IS_RUNNING = true;
        }
    }
}
```

- Việc sử dụng `jib` để build docker, cho tốc độ deploy ci thật nhanh
```xml
<plugins>
    <plugin>
        <groupId>com.google.cloud.tools</groupId>
        <artifactId>jib-maven-plugin</artifactId>
        <version>2.6.0</version>
    </plugin>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <configuration>
            <annotationProcessorPaths>
                <path>
                    <groupId>org.projectlombok</groupId>
                    <artifactId>lombok</artifactId>
                    <version>${lombok.version}</version>
                </path>
                <path>
                    <groupId>org.mapstruct</groupId>
                    <artifactId>mapstruct-processor</artifactId>
                    <version>1.4.1.Final</version>
                </path>
            </annotationProcessorPaths>
        </configuration>
    </plugin>
</plugins>
```
- Interceptor `FeignDecode` để hứng body từ FeignClient cho mục đích log. (hơi lằng nhằng vì response có thể được `gzip`)
```java
     Response finalResponse = null;
        var headerResponseEncoding = response.headers().get("content-encoding");
        if (!CollectionUtils.isEmpty(headerResponseEncoding) && headerResponseEncoding.contains("gzip")) {
            String decompressedBody = decompress(response);
            assert decompressedBody != null;
            finalResponse = response.toBuilder().body(decompressedBody.getBytes()).build();
        } else {
            finalResponse = response;
        }

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        finalResponse.body().asInputStream().transferTo(baos);
        Reader reader = new InputStreamReader(new ByteArrayInputStream(baos.toByteArray()));
        if (logClient != null) {
            logClient.setResponse(baos.toString(StandardCharsets.UTF_8));
            logClientJPARepository.save(logClient);
        }
```
- Cần 1 localCache để điều phối việc log sync khi chạy trên instance => Sử dụng CaffeeIn 
```java
@Configuration
public class CacheConfig {

    public static final int CACHE_DURATION_MINUTES = 10;

    @Bean("syncRequestCache")
    public LoadingCache<String, Boolean> syncRequestCache() {
        return Caffeine.newBuilder()
                .expireAfterWrite(CACHE_DURATION_MINUTES, TimeUnit.MINUTES)
                .build(key -> Boolean.FALSE);
    }
}
```

- Cần 1 JsonConverter để đọc msg từ Kafka
```java
    @Primary
    @Bean
    public JsonConverter jsonConverter() {
        var jsonConverter = new JsonConverter();
        var configs = new HashMap<String, Object>();
        configs.put("schemas.enable", "true");
        jsonConverter.configure(configs, false);
        return jsonConverter;
    }
```
```java
var oder = KafkaConnectHelper.convertValueToModel(record.topic(), record.value(), jsonConverter, OrderMsg.class);
```

- Cần Override lại config messageConverter khi call api 
```java
@Configuration
@EnableSpringDataWebSupport
public class WebConfig extends WebMvcConfigurationSupport {

    @Qualifier("json")
    @Autowired
    private ObjectMapper json;

    @Override
    public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
        var converter = new MappingJackson2HttpMessageConverter();
        converter.setObjectMapper(json);
        var stringHttpMessageConverter = new StringHttpMessageConverter();
        stringHttpMessageConverter.setWriteAcceptCharset(false);

        converters.add(new ByteArrayHttpMessageConverter());
        converters.add(stringHttpMessageConverter);
        converters.add(new ResourceHttpMessageConverter());
        converters.add(new SourceHttpMessageConverter<>());
        converters.add(converter);
    }

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> argumentResolvers) {
        argumentResolvers.add(new PageableHandlerMethodArgumentResolver());
    }
}
```
- Sử dụng `org.zalando.problem` để handler message lỗi cho api, cần khai báo ObjectMapper

```java
    @Bean(name = {"json"})
    public ObjectMapper json() {
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.disable(SerializationFeature.WRAP_ROOT_VALUE);
        objectMapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        objectMapper.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        objectMapper.configure(DeserializationFeature.READ_ENUMS_USING_TO_STRING, true);
        objectMapper.configure(SerializationFeature.WRITE_ENUMS_USING_TO_STRING, true);
        objectMapper.setDateFormat(new StdDateFormat());
        SimpleFilterProvider filters = new SimpleFilterProvider();
        filters.addFilter("empty", SimpleBeanPropertyFilter.serializeAllExcept(new HashSet<>()));
        filters.addFilter("field", SimpleBeanPropertyFilter.serializeAllExcept(new HashSet<>()));
        objectMapper.setFilterProvider(filters);
        objectMapper.registerModules(new ProblemModule().withStackTraces(false), new ConstraintViolationProblemModule());
        return objectMapper;
    }
```
- Customize 1 problem

```java
public class CallHttpProblem extends AbstractThrowableProblem {

    public CallHttpProblem(SourceType sourceType, FeignException exception) {
        super(null,
                "Call internal api has problem",
                Status.FAILED_DEPENDENCY,
                String.format("Call api to '%s' has problem", "xxx"),
                null, null,
                Stream.of(new String[][]{
                        {"dependency_status", String.valueOf(exception.status())},
                        {"dependency_uri", Util.getPath(exception.request().url())},
                }).collect(Collectors.toMap(data -> data[0], data -> data[1]))
        );
    }
}
```

- Tại các class `Entity`, khai báo thêm 2 method sau, để khi update/create xuống db, không phải setter value

```java
    @PreUpdate
    private void preUpdate() {
        this.modifiedOn = Util.getVNTime();
    }

    @PrePersist
    private void prePersist() {
        if (this.getCreatedOn() == null) this.setCreatedOn(Util.getVNTime());
    }
```     


- Khai báo class Exception, kiểu Builder pattern, hạn chế việc mutable  

```java 

public class SyncProductException extends RuntimeException {

    private static final long serialVersionUID = 1L;
    @Getter
    private final SyncProductErrorType errorType;
    @Getter
    private FeignException feignException;
    @Getter
    private SourceType errorFrom;

    public SyncProductException(String message, SyncProductErrorType errorType, FeignException feignException,
                                SourceType errorFrom) {
        super(message);
        this.errorType = errorType;
        this.feignException = feignException;
        this.errorFrom = errorFrom;
    }

    public SyncProductException(SyncProductErrorType errorType) {
        super(errorType.getExceptionMessage());
        this.errorType = errorType;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private SyncProductErrorType errorType;
        private String message;
        private FeignException feignException;
        private SourceType errorFrom;


        public Builder errorType(SyncProductErrorType errorType) {
            this.errorType = errorType;
            return this;
        }

        public Builder message(String message) {
            this.message = message;
            return this;
        }

        public Builder feignException(FeignException feignException, SourceType errorFrom) {
            this.errorFrom = errorFrom;
            this.feignException = feignException;
            return this;
        }

        public SyncProductException build() {
            if (this.errorType == null) throw new IllegalArgumentException("errorType not null");
            if (this.message == null) this.message = this.errorType.getExceptionMessage();
            return new SyncProductException(this.message, this.errorType, this.feignException, this.errorFrom);
        }
    }
}
```                 


- class `SyncCoordinator` , chuyển toàn bộ các `handler` thực chất là các scheduler riêng rẽ, scan db để lấy các request sync, sang duy nhất 1 scheduler, scheduler `coordinator` này sẽ quét toàn bộ db, và quản lý chúng trên local memmory, để điều phối việc sync. 
    - Nhược điểm hiện tại: đang dùng localmem => chưa thể scale được
    - Luôn phải suy nghĩ, và tính toán sao cho trong trường hợp SyncCoordinator này có lỗi, do việc quản lý mem, và điều phối không tốt, thì cũng không làm sai lệch dữ liệu đồng bộ. 
- class `ReTriggerTask` dùng để trigger, restart lại các job bị lỗi, hoặc bị treo.        

```java
@Component
@CommonsLog(topic = "topic.operate")
public class ReTriggerTask implements CommandLineRunner {
    public static final int FAIL_THRESHOLD = 10;
    @Autowired
    private SyncRequestJPARepository syncRequestJPARepository;

    @Override
    public void run(String... args) throws Exception {
        log.info("---Restart all handling request ");
        syncRequestJPARepository.restartAllHandling(ProgressStatus.processing);
    }

    @Scheduled(cron = "1 1 * ? * *")
    public void restartHangingRequest() {
        int counter = syncRequestJPARepository.countAllByProgressStatusAndPrevFireTimeBefore(ProgressStatus.processing, Util.getVNTime());
        log.info("---Restart all handling request - via cron schedule - total = " + counter);
        var now = Util.getVNTime();
        Calendar c = Calendar.getInstance();
        c.setTime(now);
        c.add(Calendar.HOUR, -1);
        syncRequestJPARepository.restartAllHandling(c.getTime());
    }

    @Scheduled(cron = "1 9 * ? * *")
    public void restartFailRequest() {
        int counter = syncRequestJPARepository.countAllByProgressStatusAndFireCounterIsLessThanEqual(ProgressStatus.fail, FAIL_THRESHOLD);
        log.info("---Restart all fail request - via cron schedule - total = " + counter);
        var now = Util.getVNTime();
        Calendar c = Calendar.getInstance();
        c.setTime(now);
        c.add(Calendar.HOUR, -1);
        syncRequestJPARepository.restartAllFail(FAIL_THRESHOLD);
    }
}
```
- `ExceptionHandlerAdvice` - advice controller          

```java

@ControllerAdvice(basePackages = "service.controller.frontend.api")
public class ExceptionHandlerAdvice implements ProblemHandling {
    private final StoreJPARepository storeJPARepository;

    public ExceptionHandlerAdvice(StoreJPARepository storeJPARepository) {
        this.storeJPARepository = storeJPARepository;
    }

    @ModelAttribute(value = "store", binding = false)
    public Store addStore(@RequestHeader(value = "X-App-StoreId", required = false) Integer storeIdHeader) {
        if (NumberUtils.isBlank(storeIdHeader)) {
            throw Problem.builder()
                    .withTitle(Status.BAD_REQUEST.getReasonPhrase())
                    .withStatus(Status.BAD_REQUEST)
                    .withDetail("Header 'X-App-StoreId' is missing or invalid")
                    .build();
        }
        val authentication = SecurityContextHolder.getContext().getAuthentication();
        JwtUser u = (JwtUser) authentication.getPrincipal();
        if (storeIdHeader != u.getId()) {
            throw Problem.builder()
                    .withTitle(Status.FORBIDDEN.getReasonPhrase())
                    .withStatus(Status.FORBIDDEN)
                    .withDetail("This token have not permission for this store!")
                    .build();
        }

        var storeOp = storeJPARepository.findById(storeIdHeader);
        if (storeOp.isEmpty()) {
            throw Problem.builder()
                    .withTitle(Status.NOT_FOUND.getReasonPhrase())
                    .withStatus(Status.NOT_FOUND)
                    .withDetail(String.format("Store %s not found", storeIdHeader))
                    .build();
        }
        return storeOp.get();
    }

    @ExceptionHandler(AccessDeniedException.class)
    public void handlerError() {
        throw Problem.builder()
                .withTitle(Status.FORBIDDEN.getReasonPhrase())
                .withStatus(Status.FORBIDDEN)
                .withDetail("Denied")
                .build();
    }
}
```
