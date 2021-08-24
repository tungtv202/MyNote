---
title: Feign Client - Client builder example
date: 2020-01-09 18:00:26
updated: 2020-01-09 18:00:26
tags:
    - http client
    - java
    - feign
category: 
    - java
    - feign
---

# Tự build FeignCLient không sử dụng anotation
- Được sử dụng trong case không muốn sử dụng chung các bean đã config sẵn cho FeignClient
- Sử dụng cách này thì tại class interface client, không cần khai báo antotation `@FeignClient`
## 1. Code example
- Config

```java
@Component
public class DemoFeignClientConfig {
    private static final List<String> profilesDev = Arrays.asList("local", "dev", "dev2");

    private final ObjectMapper json;
    private final Environment env;

    @Value("${authen.key}")
    private String SEAuthorization;

    @Value("${endpoint:http://192.168.0.42:8000}")
    private String endpoint;

    @Autowired
    public DemoFeignClientConfig(@Qualifier("json_main") ObjectMapper json, Environment env) {
        this.json = json;
        this.env = env;
    }

    @Bean
    public YourClient yourclient() {
        return Feign.builder()
                .encoder(new JacksonEncoder(json))
                .decoder(new JacksonDecoder(json))
                .logger(new Slf4jLogger("service"))
                .logLevel(feignLoggerLevel())
                .requestInterceptor(template -> {
                    template.header("Authorization", SEAuthorization);
                    template.header("Content-Type", "application/json");
                    template.header("Application-Name", "Your app name");

                })
                .contract(new SpringMvcContract())
                .target(YourClient.class, endpoint);
    }

    private Logger.Level feignLoggerLevel() {
        var profiles = env.getActiveProfiles();
        if (profiles.length == 0) {
            return Logger.Level.NONE;
        } else {
            for (var profile : profiles) {
                if (profilesDev.contains(profile)) {
                    return Logger.Level.FULL;
                }
            }
        }
        return Logger.Level.BASIC;
    }
}
```
- `YourClient` class

```java
public interface YourClient {

    @RequestMapping(value = "/api/banks", method = GET)
    BanksResponse getListBank();

    @RequestMapping(value = "/api/bank_branches", method = GET)
    BankBranchesResponse getListBankBranch(@RequestParam(value = "bankCode", required = false) String bankCode);
}
```

- Sử dụng

```java
@Autowire
private  YourClient yourclient;
```