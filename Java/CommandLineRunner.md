```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class Test implements CommandLineRunner {
    private static Logger logger = LoggerFactory.getLogger(Test.class);

    @Autowired
    private TestClient testClient;

    @Override
    public void run(String... args) {
        var result = testClient.getById(1);
    }
}
```