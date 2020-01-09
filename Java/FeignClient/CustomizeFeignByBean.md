# Customize lại FeignClient bằng cách tạo ra các Bean mặc định
- Các class interface khai báo `@FeignClient` thì sẽ mặc định sử dụng các config customize này

## 1. Code
- config
```java

@Configuration
public class FeignClientConfig {
    private UserConfig userConfig;
    private ObjectMapper main;
    private ObjectMapper json;
    private String applicationName;

    @Autowired
    public FeignClientConfig(@Autowired UserConfig userConfig, @Qualifier("json_main") ObjectMapper main, @Qualifier("json") ObjectMapper json, @Value("${spring.application.name}") String applicationName) {
        this.json = json;
        this.main = main;
        this.userConfig = userConfig;
        this.applicationName = applicationName;
    }

    @Bean
    @Primary
    public RequestInterceptor feignRequestInterceptorDefault() {
        String plainCreds = String.format("%s:%s", userConfig.getName(), userConfig.getPassword());
        byte[] plainCredsBytes = plainCreds.getBytes();
        byte[] base64CredsBytes = Base64.encodeBase64(plainCredsBytes);
        String base64Creds = new String(base64CredsBytes);
        return template -> {
            template.header("Authorization", String.format("Basic %s", base64Creds));
            template.header("Content-Type", "application/json;charset=utf-8");
            template.header("Application-Name", applicationName);
        };
    }

    @Bean
    @Primary
    public Decoder feignDecoderDefault() {
        return new ResponseEntityDecoder(new FeignDecode(main, json));
    }

    @Bean
    @Primary
    public Encoder feignEncoderDefault() {
        return new JacksonEncoder(main);
    }

    @Bean
    @Primary
    public Contract contractDefault() {
        return new SpringMvcContract();
    }

    @Bean
    public Retryer retryer() {
        return Retryer.NEVER_RETRY;
    }

    @Bean
    @Profile({"debug", "dev2"})
    public Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;
    }

    @Bean
    @Profile({"debug", "dev2"})
    public Logger logger() {
        return new Slf4jLogger("service");
    }
}

```
- FeignDecode class
```java
public class FeignDecode extends JacksonDecoder {
    private ObjectMapper main;
    private ObjectMapper json;

    public FeignDecode(ObjectMapper main, ObjectMapper json) {
        this.main = main;
        this.json = json;
    }

    @Override
    public Object decode(Response response, Type type) throws IOException {
        if (type.equals(CountResult.class)) {
            return decode(response, type, json);
        }

        return decode(response, type, main);
    }

    private Object decode(Response response, Type type, ObjectMapper mapper) throws IOException {
        if (response.status() == 404) return Util.emptyValueOf(type);
        if (response.body() == null) return null;
        Reader reader = response.body().asReader();
        if (!reader.markSupported()) {
            reader = new BufferedReader(reader, 1);
        }
        try {
            // Read the first byte to see if we have any data
            reader.mark(1);
            if (reader.read() == -1) {
                return null; // Eagerly returning null avoids "No content to map due to end-of-input"
            }
            reader.reset();
            return mapper.readValue(reader, mapper.constructType(type));
        } catch (RuntimeJsonMappingException e) {
            if (e.getCause() != null && e.getCause() instanceof IOException) {
                throw IOException.class.cast(e.getCause());
            }
            throw e;
        }
    }
}

```