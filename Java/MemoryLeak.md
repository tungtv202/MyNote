---
title: Java - Memory Leak
date: 2019-03-17 18:00:26
tags:
    - java
    - memory leak
category: 
    - java
---

# Memory leak trong Java    
![Context](https://www.baeldung.com/wp-content/uploads/2018/11/Memory-_Leak-_In-_Java.png)   
## 1. Cơ chế
- 1 là chủ động tự trigger, 2 là đợi bộ GC tự chạy. (không rõ khi nào nó được chạy, có thể khi gần hết bộ nhớ...@@)
- Có 2 giá trị xms, và xmx, cấp size nhớ lúc start, và giá trị maximum. 
- Dựa vào xmx, và kernel, os ..vvv, mà JVM sẽ tự tính toán ra size cho 2 vùng Old và Young (Eden). GC sẽ scan ở Eden trước, và thường xuyên hơn khi scan ở Old. 
- Ngoài old và eden, có thể có thêm s0, s1... để phục vụ cho cơ chế phát hiện được Object không được ref ở đâu, ít phải scan hơn.
- Có 2 pharse: Mark and sweep. Pharse Mark sẽ scan và đánh dấu các Object không được ref, Sweep sẽ scan các object không được ref và release chúng.

## 2. Các code ví dụ
    Các ví dụ sau chỉ ra các lỗi thường gặp hay đẫn tới memory leak. Và cách phòng tránh.

### 2.1, Khai báo static cho biến

```java
public class StaticTest {
    public static List<Double> list = new ArrayList<>();
 
    public void populateList() {
        for (int i = 0; i < 10000000; i++) {
            list.add(Math.random());
        }
        Log.info("Debug Point 2");
    }
 
    public static void main(String[] args) {
        Log.info("Debug Point 1");
        new StaticTest().populateList();
        Log.info("Debug Point 3");
    }
}
```
Ngay khi "Debug Point 1" được start, memory đã được cấp phát cho list Object Double. Sau khi "Debug Point 2" kết thúc, list object này không được sử dụng nữa, nhưng memory vẫn không được thu hồi.     
Ảnh phân tích:   
![vidu1](https://www.baeldung.com/wp-content/uploads/2018/11/memory-with-static.png)

Sau khi xóa khai báo static:    
![vidu2](https://www.baeldung.com/wp-content/uploads/2018/11/memory-without-static.png)

### 2.2, Sử dụng wrapper class

```java
public class Adder {
       public long addIncremental(long l)
       {
              Long sum=0L;
               sum =sum+l;
               return sum;
       }

       public static void main(String[] args) {
              Adder adder = new Adder();
              for(long ;i<1000;i++)
              {
                     adder.addIncremental(i);
              }
       }
}
```
Việc sử dụng kiểu Long trong đoạn code này là không cần thiết. 
Theo cơ chế autoboxing thì vòng lặp sẽ tạo ra 1000 Object Long.     
=> Nên sử dụng kiểu long    
=> Cần phân biệt trường hợp sử dụng giữa primitive type và wrapper class. Hãy cố gắng sử dụng primitive type nhiều nhất có thể. 

### 2.3, Unclosed Resources 
Khi mở kết nối tới database, hay mở file nhưng sau khi sử dụng xong lại không close kết nối chúng. Có thể do quên code close, hoặc đặt code close sai vị trí. Việc này sẽ dẫn tới memory leak. 
Giải pháp là luôn luôn khai báo close resources trong khối finally.     

### 2.4, Implement phương thức equals() và hashCode()   

```java
public class Person {
    public String name;
     
    public Person(String name) {
        this.name = name;
    }
}
```

```java
@Test
public void givenMap_whenEqualsAndHashCodeNotOverridden_thenMemoryLeak() {
    Map<Person, Integer> map = new HashMap<>();
    for(int i=0; i<100; i++) {
        map.put(new Person("jon"), 1);
    }
    Assert.assertFalse(map.size() == 1);
}
```
Kkhi khai báo Map và Person làm key, lúc này Map sẽ không chấp nhận việc trùng key. 
Trong class Person này, đã không implement 2 method là equals() và hashCode() => dẫn tới Map không thể get ra được. làm tăng memory cho Map, khi insert 100 phần tử Object Person.  

### 2.5, Một vài recommend
- Nên sử dụng version Java mới nhất 
- Nếu phải làm việc với biến String lớn, cần khai báo tăng size cho PermGem để tránh báo lỗi OutOfMemoryErrors

```bash
-XX:MaxPermSize=512m
```
- Sử dụng WeakHashMap để init cache thay vì HashMap như truyền thống. Với các cặp <key,value> trong WeakHashMap, nếu key không bị tham chiếu bởi object nào thì cặp <key,value> đó sẽ được GC dọn dẹp. 
- CustomKey luôn đi kèm với tính Immutable

## 3. Tool để warning + monitor memory leak
- Để cảnh báo: IDE eclipse...
![tool1](https://www.baeldung.com/wp-content/uploads/2018/11/Eclipse-_Memor-_Leak-_Warnings.png)

- Để phân tích: Java profilers  
a) JProfiler    
![tool2](https://www.baeldung.com/wp-content/uploads/2017/10/1-jprofiler-overview-probing.png)

    b) Java VisualVM    
![tool3](https://www.baeldung.com/wp-content/uploads/2017/10/6-visualvm-overview.png)

    c) NetBeans Profiler    
![tool4](https://www.baeldung.com/wp-content/uploads/2017/10/8-netbeans-telemetry-view.png)
