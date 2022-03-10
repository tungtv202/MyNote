---
title: Java - Note Total
date: 2020-02-05 18:00:26
updated: 2020-02-05 18:00:26
tags:
    - java
    - note
    - KafkaListener
category: 
    - java
---

## Collection Interface

![CollectionInterface](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/CollectionInterface.PNG)

## SerialVersionUID

- It will help define the order data of objects when serializing to bytes stream. We can only deserialize objects when
  SerialVersionUID of a class is equal to `SerialVersionUID` of instance that storage

- What happens if we don't define `SerialVersionUID`?
    - Mechanism of serializable will auto-creates the `SerialVersionUID` when runtime, that based on properties of this
      class. Suppose we did not define it and storage object. Then we modify some properties (add/remove...). We will
      get the `InvalidClassException` when trying to deserialize the object.

## Double Brace

- initialization syntax `({{ ... }}) `
- potentially creating a memory leak    
  https://stackoverflow.com/questions/1958636/what-is-double-brace-initialization-in-java

## KafkaListener - chỉ định vị trí offset + partition

```java
 @KafkaListener(
            topics = "abc.ProductLogs111",
            groupId = "tmp-remove-whenever-001",
            concurrency = "1",
            topicPartitions = @TopicPartition(topic = "abc.ProductLogs",
                    partitionOffsets = {
                            @PartitionOffset(partition = "2", initialOffset = "2049"),
                            @PartitionOffset(partition = "0", initialOffset = "2325"),
                            @PartitionOffset(partition = "1", initialOffset = "2049"),
                    })
    )
    public void listen(ConsumerRecord<String, String> record) throws InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException, IOException {
        try {
            System.out.println("topic: " + record.topic());
            System.out.println("partition: " + record.partition());
            System.out.println("offset: " + record.offset());
            System.out.println("value: " +record.value());
            System.out.println("timeStamp: " +record.timestamp());
        } catch (Exception e) {
            //logger.error("[Topic] " + record.topic() + " [Offset] " + record.offset() + " [Partition] " + record.partition() + " [Exception] ", e);
            logger.error("Kafka consumer failed: ", e);
            Sentry.capture(e);
            throw e;
        }
    }
```

- WARNING: `initialOffset` is the absolute offset that exits in Kafka. We will get an exception when try to
  set `initialOffset` as a random number, that smaller some offset, that we want

## @Lazy

// TODO

## HashMap

is not limited. That's the maximum number of buckets. Each bucket uses a form of linked list which has no limitation
except memory. So in theory a HashMap can hold an unlimited number of elements. In practice, you won't even get to 2^30
because you will have run out of memory long before that.

## MappedSuperclass

Can not using both `@MappedSuperclass` and `@Entity` in same time.

## CommandLineRunner

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

## NumberUtils

```java
public class NumberUtils {
    public static boolean isNotBlank(final Number number) {
        return !(number == null ||
                (
                        number instanceof Integer ? number.intValue() == 0 :
                                number instanceof Long ? number.longValue() == 0 :
                                        number instanceof Double ? number.doubleValue() == 0 :
                                                number instanceof Short ? number.shortValue() == 0 :
                                                        number.floatValue() == 0
                ));
    }

    public static boolean isBlank(final Number number) {
        return !isNotBlank(number);
    }

    public static boolean isEqual(int v1, Integer v2) {
        if (v2 == null) return false;
        return v1 == v2;
    }
}
```

## CompressHelper

```java
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

public class CompressHelper {

    public static byte[] gzipCompress(byte[] input) {
        try {
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            InputStream inputStream = new ByteArrayInputStream(input);
            GZIPOutputStream gzipOS = new GZIPOutputStream(outputStream);
            byte[] buffer = new byte[1024];
            int len;
            while ((len = inputStream.read(buffer)) != -1) {
                gzipOS.write(buffer, 0, len);
            }
            gzipOS.close();
            inputStream.close();
            outputStream.close();
            return outputStream.toByteArray();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    public static byte[] gzipDecompress(byte[] input) {
        try {
            GZIPInputStream gis = new GZIPInputStream(new ByteArrayInputStream(input));
            ByteArrayOutputStream fos = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int len;
            while ((len = gis.read(buffer)) != -1) {
                fos.write(buffer, 0, len);
            }
            //close resources
            fos.close();
            gis.close();
            return fos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
```

## Spring valid enum

```java
@Target({ElementType.METHOD, ElementType.FIELD, ElementType.ANNOTATION_TYPE, ElementType.CONSTRUCTOR, ElementType.PARAMETER, ElementType.TYPE_USE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Constraint(validatedBy = DoTypeValidator.class)
public @interface DoTypeValid {
    DoSomethingType[] anyOf();
    String message() default "must be any of {anyOf}";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}
```

```java
public class DoTypeValidator implements ConstraintValidator<DoTypeValid, DoSomethingType> {
    private DoSomethingType[] doSomethingTypes;

    @Override
    public void initialize(DoTypeValid constraintAnnotation) {
        this.doSomethingTypes = constraintAnnotation.anyOf();
    }

    @Override
    public boolean isValid(DoSomethingType doSomethingType, ConstraintValidatorContext constraintValidatorContext) {
        return doSomethingType == null || Arrays.asList(doSomethingTypes).contains(doSomethingType);
    }
}
```

Using:

```java
    @DoTypeValid(anyOf = {DoSomethingType.re_sync})
    @NotNull
    private DoSomethingType doType;
```

## MapConverter - for hibernate, java hashmap, db string

```java
@Converter
public class MapConverter implements AttributeConverter<Map<String, String>, String> {

    @Override
    public String convertToDatabaseColumn(Map<String, String> attribute) {
        return Util.convertMapToString(attribute);
    }

    @Override
    public Map<String, String> convertToEntityAttribute(String dbData) {
        return Util.convertStringToMap(dbData);
    }
}
```

Using in Entity class

```java
    @Convert(converter = MapConverter.class)
    private Map<String, String> metaData;
```

## Valid - String in List

```java
@Documented
@Constraint(validatedBy = StringInListValidator.class)
@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Order(value = Ordered.LOWEST_PRECEDENCE)
public @interface StringInList {
    String[] array() default {};

    boolean allowBlank() default false;

    String message() default "invalid";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
```

```java
public class StringInListValidator implements
        ConstraintValidator<StringInList, String> {
    private StringInList stringInList;

    @Override
    public void initialize(StringInList stringInList) {
        this.stringInList = stringInList;
    }

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        boolean isValid = false;
        if (stringInList.allowBlank()) {
            if (StringUtils.isEmpty(value)) {
                isValid = true;
            }
        }

        if (!isValid) {
            isValid = ArrayUtils.contains(stringInList.array(), value);
        }

        if (!isValid) {
            context.disableDefaultConstraintViolation();

            String message = String.format("is not in %s",
                    Arrays.asList(stringInList.array()));

            context.buildConstraintViolationWithTemplate(message)
                    .addConstraintViolation();
        }
        return isValid;
    }
}
```

Using

```java
    @StringInList(array = {"product", "order"}, allowBlank = true)
    private String errorType;
```

## Optional.stream()

1. Bad

```java
public BigDecimal getOrderPrice(Long orderId) {
    List<OrderLine> lines = orderRepository.findByOrderId(orderId);
    BigDecimal price = BigDecimal.ZERO;       
    for (OrderLine line : lines) {
        price = price.add(line.getPrice());   
    }
    return price;
}
```

2. Bad

```java
public BigDecimal getOrderPrice(Long orderId) {
    List<OrderLine> lines = orderRepository.findByOrderId(orderId);
    return lines.stream()
                .map(OrderLine::getPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
}
```

and ...

```java

public BigDecimal getOrderPrice(Long orderId) {
    if (orderId == null) {
        throw new IllegalArgumentException("Order ID cannot be null");
    }
    List<OrderLine> lines = orderRepository.findByOrderId(orderId);
    return lines.stream()
                .map(OrderLine::getPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
}
```

3. bad

```java
public BigDecimal getOrderPrice(Long orderId) {
    return Optional.ofNullable(orderId)                            
            .map(orderRepository::findByOrderId)                   
            .flatMap(lines -> {                                    
                BigDecimal sum = lines.stream()
                        .map(OrderLine::getPrice)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                return Optional.of(sum);                           
            }).orElse(BigDecimal.ZERO);                            
}
```

4. perfect

```java
public BigDecimal getOrderPrice(Long orderId) {
    return Optional.ofNullable(orderId)
            .stream()
            .map(orderRepository::findByOrderId)
            .flatMap(Collection::stream)
            .map(OrderLine::getPrice)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
}
```

## check isPrivateIP

```java
public static boolean isPrivateIP(HttpServletRequest request) {
        return isPrivateIP(getRemoteIP(request));
    }

    public static boolean isPrivateIP(String ip) {
        InetAddress address;
        try {
            address = InetAddress.getByName(ip);
        } catch (UnknownHostException exception) {
            return false;
        }
        return address.isSiteLocalAddress() || address.isAnyLocalAddress() || address.isLinkLocalAddress()
                || address.isLoopbackAddress() || address.isMulticastAddress();

    }

    public static String getRemoteIP(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (null != ip && !"".equals(ip.trim()) && !"unknown".equalsIgnoreCase(ip)) {
            // get first ip from proxy ip
            int index = ip.indexOf(',');
            if (index != -1) {
                return ip.substring(0, index);
            } else {
                return ip;
            }
        }

        ip = request.getHeader("X-Real-IP");
        if (null != ip && !"".equals(ip.trim()) && !"unknown".equalsIgnoreCase(ip)) {
            return ip;
        }

        return request.getRemoteAddr();
    }
```

## Pro tip

- The statement return null; makes the lambda into a `Callable` instead of a `Runnable`, so that you don’t have to catch
  checked exceptions

```java
exec.submit(() -> {
    process(something);
    return null;
});
```

## Load properties from file 

```java

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

public class ExtraProperties {

    public static final String OVERRIDE_PROPERTY = "extra.props";
    public static final String DEFAULT_PATH = "conf/jvm.properties";

    public static void initialize() {
        String propsPath = System.getProperty(OVERRIDE_PROPERTY, DEFAULT_PATH);
        try (FileInputStream in = new FileInputStream(propsPath)) {
            System.getProperties().load(in);
        } catch (FileNotFoundException e) {
            if (!DEFAULT_PATH.equals(propsPath)) {
                JamesServerMain.LOGGER.warn("Could not find extra system properties file {}", propsPath);
            }
        } catch (IOException e) {
            JamesServerMain.LOGGER.warn(
                    "Failed to load extra system properties from file {} : {}", propsPath, e.getMessage());
        }
    }
}

```

```java
 public static void main(String[] args) throws Exception {
        ExtraProperties.initialize();
    }
```

- Command: `java -jar -Dmy.property=/home/tungtv/workplace/jvm123.properties`
- Sample file `jvm123.properties`

```
# my.property=whatever
LOAD_ABC=true
```

## String equals() Vs contentEquals()
```java
String actualString = "baeldung";
CharSequence identicalStringBufferInstance = new StringBuffer("baeldung");

assertFalse(actualString.equals(identicalStringBufferInstance));
assertTrue(actualString.contentEquals(identicalStringBufferInstance));
```

## Concurrent thread will not care to `static` method

```java
public class ThreadStaticMethod {

    @SneakyThrows
    public static void staticMethod() {
        System.out.println(Thread.currentThread().getName() + " - " + new Date());
        TimeUnit.SECONDS.sleep(5);
    }


    public static void main(String[] args) {
        for (int i = 1; i < 10; i++) {
            new Thread(ThreadStaticMethod::staticMethod).start();
        }
    }
}
```
output:
```
Thread-2 - Tue Jan 11 21:52:51 ICT 2022
Thread-0 - Tue Jan 11 21:52:51 ICT 2022
Thread-3 - Tue Jan 11 21:52:51 ICT 2022
Thread-1 - Tue Jan 11 21:52:51 ICT 2022
```

## AutoCloseable  - try-with-resource

```java
@Slf4j
public class AutoCloseableDemo {

    @AllArgsConstructor
    static class CustomCloseable implements AutoCloseable {
        @Getter
        @Setter
        private String value;

        @Override
        public void close() throws Exception {
            System.out.println("Closed : " + value);;
        }
    }

    public static void main(String[] args) throws Exception {
        try (CustomCloseable test = new CustomCloseable("Tung")) {
            System.out.println(test.getValue());
        }
    }
}
```
```
Tung
Closed : Tung
```

## Why we need `Thread.currentThread().interrupt();` 

```java
            try {
               // some thing
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
```
- it helps parent can handler InterruptedException. (In this exception has a flag, when we try catch it, that flag has been update, so the `Thread.currentThread().interrupt();` help recovery the state of flag)

## Dequeue vs Stack
- Stack is threadSafe, DeQueue is not

## PhantomReference
https://openplanning.net/13697/java-phantomreference
Về cơ bản PhantomReference cung cấp cho bạn khả năng xác định chính xác khi nào đối tượng innerObject của nó bị xoá khỏi bộ nhớ. Phương thức phantomRef.isEnqueued() trả về true nghĩa là đối tượng innerObject đã bị xoá bỏ khỏi bộ nhớ. Khi đối tượng innerObject bị xoá khỏi bộ nhớ thì đối tượng phantomRef sẽ được đặt vào hàng đợi (queue).