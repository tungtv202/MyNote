---
title: Jackson - Note
date: 2019-12-21 18:00:26
tags:
    - serialize
    - java
    - jackson
category: 
    - java
    - jackson
---

# Jackson 
```
com.fasterxml.jackson.core
```

![JackSon Architect](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jackson/JackSon1.JPG)

## 1. annotation
### 1.1 @JsonProperty

```java
    public class Employee {
        @JsonProperty("employee-name")
        private String name;

        @JsonProperty("employee-code")
        private String code;
    }
    // Code demo at: DemoJsonProperty.java
```

- Trong cả case serialization và deserialization: 
    - A = "name","code" => A1 = "employee-name", "employee-code"
    - B = "name", B1 = "employee-name", "employee-code"


### 1.2 @JsonGetter @JsonSetter

```java
    public  class Employee {
        private String name;

        @JsonGetter("employee-name-1")
        public String getName() {
            return name;
        }

        @JsonSetter("employee-name-2")
        public void setName(String name) {
            this.name = name;
        }
    }
    // code demo at: DemoJsonSetterGetter.java
```
- Trong case serialization
    - A = "name" => A1= "employee-name-1"
- Trong case deserialization
    - B1 = "employee-name-2" => B = "name"
- Trường hợp @JsonGetter và @JsonSetter có value bằng nhau, thì tương đương dùng @JsonProperty 
- Trường hợp deserialization lỗi do không tìm thấy properties, có thể cần phải config ObjectMapper 
```java
    objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
```      
    
### 1.3 @JsonIgnore

```java
    public static class Employee {
        @JsonIgnore
        private String name;
        @JsonProperty("employee-code")
        private String code;
    }
    // code demo at DemoJsonIgnore.java
```
- Case serialization
    - A = name, code 
        - A1 = employee-code  (note: A1 không có employee-name, chứ không phải employee-code = null)
    - Case deserialization
        - B1 = name, employee-code
        - B = name , code  (note: name = null)
    - Trường hợp lỗi deserialization     
``` java
    objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
```

### 1.4 @JsonIgnoreProperties

```java
    @JsonIgnoreProperties(value = {"name","code"}, ignoreUnknown = true)
    public static class Employee {
            private String name;
            private String code;
            @JsonProperty("employee-address")
            private String address;
        }   
        // demo code at DemoJsonIgnoreProperties.java
```
- Logic serialization và deserialization giống với @JsonIgnore
- Dùng trong trường hợp muốn ignore nhiều trường cùng lúc
- Khai báo "ignoreUnknown = true" tương đương với config ObjectMapper: 
```
    (DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
```

### 1.5 @JsonIgnoreType

```java
private static class Employee {
        private String name;
        private String dept;
        private Address address;
    }

    @JsonIgnoreType
    private static class Address {
        private String street;
        private String city;
    }
    // code demo at DemoJsonIgnoreType.java
```
- Dùng để ignore, giống với @JsonIgnore, nhưng thay vì đặt trên method, thì đặt trên class.
Bên trên tương đương với

```java
private static class Employee {
        private String name;
        private String dept;
        @JsonIgnore
        private Address address;
    }

    private static class Address {
        private String street;
        private String city;
    }
```

### 1.6 @JacksonInject 

```java
 @JacksonInject("lastUpdated")
  private LocalDateTime lastUpdated;
//   .......
//   .......
//   .......
 InjectableValues iv = new InjectableValues.Std();
      ((InjectableValues.Std) iv).addValue("lastUpdated", LocalDateTime.now());
```
- Dùng để set giá trị cho đặc tính, mà không cần thông qua append string vào B1, khi deserialization

### 1.7 @JsonPropertyOrder

```java
@JsonPropertyOrder({"name", "phoneNumber","email", "salary", "id" })
public class Employee {
  private String id;
  private String name;
  private int salary;
  private String phoneNumber;
  private String email;
    .............
}
```
- order theo alphabet

```java

@JsonPropertyOrder(alphabetic = true)
public class Employee2 {
  private String id;
  private String name;
  private int salary;
  private String phoneNumber;
  private String email;
    .............
}
```

### 1.8 @JsonAlias Annotation
- Chỉ có ý nghĩa khi deserialization
- 1 properties có thể khai báo nhiều Alias (JsonProperties thì chỉ khai báo được 1 giá trị)
- Có thể có B1', B1'' => B
```java
public class Employee {
  private String name;
  @JsonAlias({"department", "employeeDept" })
  private String dept;
    .............
}
```

### 1.9 @JsonCreator
```java
 @JsonCreator
        public Employee(@JsonProperty("name") String name, @JsonProperty("dept") String dept) {
            System.out.println("'constructor invoked'");
            this.name = name;
            this.dept = dept;
        }
```
- Giống JsonProperties, khác ở điểm khai báo ở Constructor, không phải bên trên properties
- Chỉ có ý nghĩa khi Deserialize

### 1.20 @ConstructorProperties 
```java
@ConstructorProperties({"name", "dept"})
  public Employee(String name, String dept) {
      System.out.println("Constructor invoked");
      //Java 9 StackWalker to find out the caller
      System.out.println("caller: " + StackWalker.getInstance(
              StackWalker.Option.RETAIN_CLASS_REFERENCE).getCallerClass());
      this.name = name;
      this.dept = dept;
  }
```
- Giống JsonCreator, nhưng khai báo multi 1 lúc

### 1.21 @JsonSerialize @JsonDeserialize
```java
@JsonSerialize(converter = LocalDateTimeToStringConverter.class)
@JsonDeserialize(converter = StringToLocalDatetimeConverter.class)
private LocalDateTime lastUpdated;
```
```java
public class LocalDateTimeToStringConverter extends StdConverter<LocalDateTime, String> {
  static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM);

  @Override
  public String convert(LocalDateTime value) {
      return value.format(DATE_FORMATTER);
  }
}
```

### 1.22 @JsonInclude
```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Employee {
  private String name;
  private String dept;
  private String address;
}
```
- Trường nào khi serialize có properties = null, thì trường đó sẽ không có trong json trả về (không có, chứ không phải có mà bằng null)
- Cách config khác tương tự:
```java
ObjectMapper om = new ObjectMapper();
        om.setDefaultPropertyInclusion(JsonInclude.Include.NON_NULL);
```
- Danh sách JsonInclude.Include...
```java
        ALWAYS 
        NON_NULL
        NON_ABSENT
        NON_EMPTY
        NON_DEFAULT
        CUSTOM
        USE_DEFAULTS
```

```java
  @JsonInclude(value = JsonInclude.Include.NON_EMPTY, content = JsonInclude.Include.NON_EMPTY)
  private AtomicReference<String> address;
```
```java
@JsonInclude(content = JsonInclude.Include.CUSTOM, contentFilter = PhoneFilter.class)
  private Map<String, String> phones;

//   
public class PhoneFilter {
  private static Pattern phonePattern = Pattern.compile("\\d{3}-\\d{3}-\\d{4}");

  @Override
  public boolean equals(Object obj) {
      if (obj == null || !(obj instanceof String)) {
          return false;
      }
      //phone must match the regex pattern
      return !phonePattern.matcher(obj.toString()).matches();
  }
}
```

### 1.23 @JsonFormat
```java
@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy/MM/dd", timezone = "America/Chicago" )
  private Date customerSince;
```
- format định dạng thời gian trả về
```java
 @JsonFormat(shape = JsonFormat.Shape.NUMBER)
  private Dept dept;

// 
public enum Dept {
  Admin, IT, Sales
}
```
- format định dạng Enum trả về

### 1.24 @JsonView
- Tạo ra 1 interface chứa nhiều kiểu VIEW
- trước mỗi properties khai báo properties đó sẽ được sử dụng ở View nào
- Khi serialization thì cần khai báo kiểu View ở objectMapper với mode View tương ứng, chỉ các properties có khai báo kiểu view mới hiện ra
```java
@JsonView({Views.DemoView.class})
        private String address;
        @JsonView({Views.QuickContactView.class})
        private String phone;
// 
public static class Views {
        interface QuickContactView {}
        interface DetailedView{}
        interface DemoView{}
    }
// 
ObjectMapper om = new ObjectMapper();
        String jsonString = om.writerWithView(Views.DemoView.class)
                .writeValueAsString(customer);
```

### 1.25 @JsonUnwrapped
- trường hợp serialize/deserialize, không muốn class con được gọi bên trong class cha, có cấu trúc json cha/con
```java
public class Employee {
  private String name;
  @JsonUnwrapped
  private Department dept;
}

//
public class Department {
  private String deptName;
  private String location;
    .............
}
```
- Output trường hợp có dùng JsonUnwrapped
```json
{"name":"Amy","deptName":"Admin","location":"NY"}
```
- Output trường hợp không dùng JsonUnwrapped
```json
{"name":"Amy","dept":{"deptName":"Admin","location":"NY"}}
```
- Có thể config thêm prefix-suffix
```java
@JsonUnwrapped(prefix = "dept-")
private Department dept;
```

### 1.26 @JsonAnyGetter
- serialize
```java
@JsonAnyGetter
    public Map<String, Object> getOtherInfo() {
        return otherInfo;
    }
```
- Có dùng JsonAnyGetter
```json
{"id":"TradeDetails","title":"Trade Details","width":500,"height":300,"xLocation":400,"yLocation":200}
```
- Không dùng 
```json
{"id":"TradeDetails","title":"Trade Details","width":500,"height":300,"otherInfo":{"xLocation":400,"yLocation":200}}
```

### 1.27 @JsonEnumDefaultValue
```java
public enum EmployeeType {
  FullTime,
  PartTime,
  @JsonEnumDefaultValue
  Contractor;
}
//
ObjectMapper om = new ObjectMapper();
om.enable(DeserializationFeature.READ_UNKNOWN_ENUM_VALUES_USING_DEFAULT_VALUE);
```

### 1.28 @JsonRootName
```java
@JsonRootName("Person")
public class PersonEntity {
  private String name;
  private int age;
    .............
}
```
- dùng để define root khi des/se

### 1.29 @JsonFilter
### 1.30 @JsonMerge

## 2. Config ObjectMapper Example
```java

@Component
@Configuration
public class ObjectMapperConfig {

    @Bean(name = "json_main")
    @Primary
    public ObjectMapper main() {
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(SerializationFeature.WRAP_ROOT_VALUE, true);
        objectMapper.configure(DeserializationFeature.UNWRAP_ROOT_VALUE, true);
        objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
        objectMapper.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        objectMapper.setDateFormat(new ISO8601DateFormat());
        SimpleModule module = new SimpleModule();
        module.addDeserializer(String.class, new StringDeserializer());
        SimpleFilterProvider filters = new SimpleFilterProvider();
        filters.addFilter("empty", SimpleBeanPropertyFilter.serializeAllExcept(new HashSet<>()));
        filters.addFilter("field", SimpleBeanPropertyFilter.serializeAllExcept(new HashSet<>()));
        objectMapper.setFilterProvider(filters);
        objectMapper.registerModule(module);
        return objectMapper;
    }
}
```

- ref: https://www.logicbig.com/tutorials/misc/jackson.html