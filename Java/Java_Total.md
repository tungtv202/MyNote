---
title: Java - Note Total
date: 2020-02-05 18:00:26
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
- Là giá trị dùng để định nghĩa thứ tự data của object khi serialize thành byte stream, chúng ta chỉ deserialize object chỉ khi SerialVersionUID của class đúng với SerialVersionUID của instance được lưu trữ.
- Không định nghĩa SerialVersionUID thì sao?
    - Cơ chế của Serializable sẽ tự động tạo SerialVersionUID trong quá trình runtime dựa vào các thuộc tính của class, nếu chúng ta không định nghĩa SerialVersionUID và lưu trữ object. Sau đó nếu chúng ta có một vài thay đổi của class và cơ chế của Serializable sẽ tạo ra một SerialVersionUID khác với SerialVersionUID  của instance đang được lưu trữ, chúng ta sẽ gặp lỗi InvalidClassException khi deserialize object (xem thêm về exception tại đây). Do đó phải luôn luôn nhớ định nghĩa SerialVersionUID cho class khi implement Serializable.
    - Cài đặt warning mặc định của eclipse sẽ cảnh báo “The Serializable class User does not declare a static final SerialVersionUID field of type long” khi chúng ta không định nghĩa SerialVersionUID và suggest chúng ta tạo SerialVersionUID. Thực chất SerialVersionUID được tạo ra bởi serialver tool nằm trong thư mục bin cài đặt Java
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

- Lưu ý: `initialOffset` phải là số có thật trong kafka, chứ không phải logic set initialOffset 1 số bất kỳ bé hơn 1 offset nào đó mà mình mong muốn.

## @Lazy 
// TODO
## HashMap 
is not limited. That's the maximum number of buckets. Each bucket uses a form of linked list which has no limitation except memory. So in theory a HashMap can hold an unlimited number of elements. In practice you won't even get to 2^30 because you will have run out of memory long before that.

## MappedSuperclass
Không thể sử dụng @MappedSuperclass và @Entity cùng lúc

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
Sử dụng
```java
    @DoTypeValid(anyOf = {DoSomethingType.re_sync})
    @NotNull
    private DoSomethingType doType;
```

## MapConverter - cho hibernate, java hashmap, db string
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
Sử dụng tại class Entity
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
Sử dụng
```java
    @StringInList(array = {"product", "order"}, allowBlank = true)
    private String errorType;
```
