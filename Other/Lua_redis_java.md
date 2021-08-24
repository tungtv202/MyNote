---
title: Run lua script on Java
date: 2018-04-09 18:00:26
updated: 2018-04-09 18:00:26
tags:
    - script
    - lua
    - redis
category: 
    - other
---

# Cách chạy script lua  thao tác với Redis trong Java

Trái với sql thuần, redis gặp khó khăn trong việc viết các câu query execute với data.  
Các lệnh command mà redis hỗ trợ, chỉ thực hiện được các lệnh đơn giản. Muốn phức tạp hơn, bắt buộc phải viết thành script. Redis hỗ trợ việc chạy script bằng ngôn ngữ LUA.

Cách viết script với LUA, tham khảo tại đây: 

http://www.lua.org/docs.html

Bài tutorial này thực hiện với SpringFramework Java

## 1. Chuẩn bị
Để chạy được script lua Redis bằng java, cần các thư viện sau:
- Spring framework scripting  

Mục đích: khai báo script trong spring

```xml
<!-- https://mvnrepository.com/artifact/org.springframework.integration/spring-integration-scripting -->
<dependency>
    <groupId>org.springframework.integration</groupId>
    <artifactId>spring-integration-scripting</artifactId>
    <version>5.0.4.RELEASE</version>
</dependency>

```

- RedisScript  
// là gói package đi kèm của springframe work data redis
Mục đích: convert script spring sang Script Redis, và thực thi

```xml
<!-- https://mvnrepository.com/artifact/org.springframework.data/spring-data-redis -->
<dependency>
    <groupId>org.springframework.data</groupId>
    <artifactId>spring-data-redis</artifactId>
    <version>1.0.0.RELEASE</version>
</dependency>
```

## 2. Demo
Tình huống: trong redis, mình có 1 key là SET_KEY_DEMO, key này có kiểu dữ liệu là SET, và bây giờ mình muốn chuyển nó sang key mới là LIST_KEY_DEMO, và có kiểu dữ liệu là LIST. Mình sẽ viết lua script và chạy việc convert này bằng Java

### 2.1 Script lua

```lua
local keySetSource = KEYS[1]
local keyListTarget = KEYS[2]
local setMembers = redis.call('SMEMBERS', keySetSource)
local count = 0
redis.call('DEL', keyListTarget)
for k, v in pairs(setMembers) do
    redis.call('LPUSH', keyListTarget, v)
    count = count + 1
end
return count
```
Trong đó keySetSource là tên của KEY kiểu SET (SET_KEY_DEMO), keyListTarget là tên của KEY kiểu LIST (LIST_SET_DEMO).
setMembers là danh sách các phần tử trong SET_KEY_DEMO.
Sử dụng vòng lặp for, để đẩy từng phần tử 1 của SET sang LIST.

### 2.2 Định nghĩa RedisScript

```java
import org.springframework.data.redis.core.script.RedisScript;
//
  @Bean(name = "copySetToListScript")
    public RedisScript<Long> copySetToListScript() {
        ScriptSource scriptSource = new ResourceScriptSource(
                new ClassPathResource("META-INF/lua-scripts/copy_set_to_list.lua"));
        DefaultRedisScript<Long> script = new DefaultRedisScript<>();
        script.setScriptSource(scriptSource);
        script.setResultType(Long.class);
        return script;
    }
```

// Cần thực hiện 1 bước convert trung gian từ ScriptSource sang DefaultRedisScript

### 2.3 Execute RedisScript bằng StringRedisTemplate

```java
public Long copySetToList(String keySet, String keyList) {
        return template.execute(copySetToListScript, Arrays.asList(keySet, keyList));
    }
```
Trong đó template chính là StringRedisTemplate.

```java
@Autowired
    private StringRedisTemplate template;
```

template này đã được khai báo về IP server Redis, port, password trước đó.

### 2.4 Thực hiện run function

```java
copySetToList("SET_KEY_DEMO", "LIST_KEY_DEMO");
```