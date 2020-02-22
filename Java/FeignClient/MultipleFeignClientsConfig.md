# Multiple Configurations for Feign Clients
Mục đích khi có nhiều FeignClient, và mỗi client có 1 config riêng biệt.
- Tham khảo: https://medium.com/@shokri4971/multiple-configurations-for-feign-clients-aeaacb8f0edd
```java
public class BarConfig {

    @Bean
    public BarRequestInterceptor barRequestInterceptor() {
        return new BarRequestInterceptor();
    }
}
public class FooConfig {

    @Bean
    public FooRequestInterceptor fooRequestInterceptor() {
        return new FooRequestInterceptor();
    }
}
```
## Khai báo RequestTemplate (cái này quan trọng nhất)
```java
public class BarRequestInterceptor implements RequestInterceptor {
    private static final Logger LOGGER = LoggerFactory.getLogger(BarRequestInterceptor.class);

    @Override
    public void apply(RequestTemplate template) {
        template.header("authorization", "auth-bar");
        LOGGER.info("bar authentication applied");
    }
}
public class FooRequestInterceptor implements RequestInterceptor {
    private static final Logger LOGGER = LoggerFactory.getLogger(FooRequestInterceptor.class);

    @Override
    public void apply(RequestTemplate template) {
        template.header("authorization", "auth-foo");
        LOGGER.info("foo authentication applied");
    }
}
```
## Sử dụng
```java
@FeignClient(contextId = "fooContextId", value = "fooValue", url = "http://foo-server.com/services", configuration = FooConfig.class)
public interface FooFeignClient {

    @GetMapping("{id}/foo")
    void getFoo(@PathVariable("id") Long id);
}
```
```java
@FeignClient(contextId = "barContextId", value = "barValue", url = "http://bar-server.com/services", configuration = BarConfig.class)
public interface BarFeignClient {

    @GetMapping("{id}/bar")
    void getBar(@PathVariable("id") Long id);
}
```

// end