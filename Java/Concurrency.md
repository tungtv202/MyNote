---
title: Java - Concurrency
date: 2020-09-30 18:00:26
tags:
    - java
    - concurrency
    - thread local
    - volatile
    - thread safe
    - completable future
category: 
    - java
---


## ThreadLocal
- Tư tưởng là mỗi thread, sẽ có 1 "vùng nhớ" riêng để chứa dữ liệu, khi các method ở các class khác nhau, được chạy trong cùng 1 thread, sẽ lấy được giá trị ở "vùng nhớ" đó.
=> Ví dụ có thể áp dụng trong case muốn tạo ra 1 Context, thay vì phải truyền các giá trị thông qua Parameter.
- Thread nào lấy được dữ liệu của thread đó, nên có thể áp dụng trong việc thread safe
- Cần cẩn thận khi sử dụng kèm vs ThreadPool, vì có thể sẽ xảy ra tình huống, 1 task mới, được chạy bởi 1 Thread trong "thread pool", thì nó sẽ lấy được dữ liệu cũ, do một task khác
chạy trước đó, bởi chính Thread đấy.
- [http://drunkkid2000.blogspot.com](http://drunkkid2000.blogspot.com/2013/07/thread-local_2564.html)
- [jenkov](http://tutorials.jenkov.com/java-concurrency/threadlocal.html)

### Code example
- InheritableThreadLocal: 
    - sử dụng thằng này để các ChildThread được tạo bởi ParentThread, có thể sử dụng "bản sao copy" từ ParentThread. (Tức là khi ChildThread sửa giá trị, thì giá trị ở ParentThread không ảnh hưởng gì)
    - các ChildThread không share chung vùng nhớ với nhau.

```java
public static void main(String[] args) {

        ThreadLocal<String> threadLocal = new ThreadLocal<>();
        InheritableThreadLocal<String> inheritableThreadLocal =
                new InheritableThreadLocal<>();

        Thread thread1 = new Thread(() -> {
            System.out.println("===== Thread 1 =====");
            threadLocal.set("Thread 1 - ThreadLocal");
            inheritableThreadLocal.set("Thread 1 - InheritableThreadLocal");

            System.out.println(threadLocal.get());
            System.out.println(inheritableThreadLocal.get());

            Thread childThread = new Thread(() -> {
                System.out.println("===== ChildThread =====");
                System.out.println(threadLocal.get());
                System.out.println(inheritableThreadLocal.get());
                inheritableThreadLocal.set("TUNG");
                System.out.println(inheritableThreadLocal.get());
            });

            Thread childThread2 = new Thread(() -> {
                try {
                    TimeUnit.SECONDS.sleep(3);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("===== ChildThread2 =====");
                System.out.println(threadLocal.get());
                System.out.println("Check: " + inheritableThreadLocal.get());
            });
            childThread.start();
            childThread2.start();

            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(inheritableThreadLocal.get());
            inheritableThreadLocal.set("TUNG2");
        });

        thread1.start();

//        Thread thread2 = new Thread(() -> {
//            try {
//                Thread.sleep(3000);
//            } catch (InterruptedException e) {
//                e.printStackTrace();
//            }
//
//            System.out.println("===== Thread2 =====");
//            System.out.println(threadLocal.get());
//            System.out.println(inheritableThreadLocal.get());
//        });
//        thread2.start();
    }
```

## Volatile 
- khai báo variable sẽ được đọc ghi trực tiếp từ main memory. (nếu không khai báo bình thường có thể nó sẽ đọc ghi từ CPU Cache để tăng performance. Dẫn tới vấn đề các thread đọc ghi giá trị không phải là mới nhất).

![Volatile222](https://images.viblo.asia/59d1214d-4438-4f46-878f-5db8af35fa1c.png)
## ThreadSafe
### XSync
- Sử dụng thư viện xsync để hỗ trợ trong việc threadsafe, các thread sẽ phải đợi nhau, để cùng vào sử dụng 1 resource

```xml
        <dependency>
            <groupId>com.antkorwin</groupId>
            <artifactId>xsync</artifactId>
            <version>1.1</version>
        </dependency>
```

```java
// method
public void timeWaitLimit(String storeAlias) {
        xSync.execute(storeAlias, () -> {
            LeakyBucketModel model = BucketLeakyStatic.get(storeAlias);
            if (model == null) {
                log.debug(storeAlias + "-init");
                BucketLeakyStatic.put(storeAlias, new LeakyBucketModel(bucketSize));
            } else {
                log.debug(storeAlias + "-" + model.getAllowCounter() + "/" + bucketSize);
                if (model.getAllowCounter() <= 0) {
                    try {
                        TimeUnit.MILLISECONDS.sleep(1200);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    int diffSecond = (int) TimeUnit.SECONDS.convert(Util.getUTC().getTime() - model.getModifiedTime(), TimeUnit.MILLISECONDS);
                    int reNewCounter = Math.min(diffSecond * drainRate, bucketSize);
                    model.reInitCounter(reNewCounter);
                }
                model.decrementCounter();
            }
        });
    }

// LeakyBucketModel.class
public class LeakyBucketModel {
    private int allowCounter;
    private long modifiedTime;

    public LeakyBucketModel(int allowCounter) {
        this.allowCounter = allowCounter;
        this.modifiedTime = Util.getUTC().getTime();
    }

    public void decrementCounter() {
        this.allowCounter -= 1;
        this.modifiedTime = Util.getUTC().getTime();
    }

    public void reInitCounter(int allowCounter) {
        this.allowCounter = allowCounter;
        this.modifiedTime = Util.getUTC().getTime();
    }

    public int getAllowCounter() {
        return this.allowCounter;
    }
    public long getModifiedTime() {
        return this.modifiedTime;
    }
}

```

## CompletableFuture
### Example api tính fee GHN

```java
 private GHNV2CalFeeDetailResponse calculator(int storeId, GHNV2CalculatorFeeRequest request) {
        String token = getToken(storeId);
        var clientResponse = client.calculatorFee(token, request);
        try {
            log.debug("--- calculator fee request --Token=" + token +
                    ", " + json.writeValueAsString(request) + "\n --- response " + json.writeValueAsString(clientResponse));
        } catch (Exception ignored) {
        }
        if (clientResponse == null || clientResponse.getCode() != 200) return null;
        var result = mapper.toDetailResponse(clientResponse);
        result.setRequest(request);
        return result;
    }

    private CompletableFuture<GHNV2CalFeeDetailResponse> calculatorFeeAsync(int storeId, GHNV2CalculatorFeeRequest request) {
        return CompletableFuture.supplyAsync(() -> calculator(storeId, request));
    }

    public List<GHNV2CalFeeDetailResponse> calculatorFee(int storeId, List<GHNV2CalculatorFeeRequest> requests) {
        if (CollectionUtils.isEmpty(requests)) return null;
        List<CompletableFuture<GHNV2CalFeeDetailResponse>> listAsync = new ArrayList<>();
        requests.forEach(e -> {
            listAsync.add(calculatorFeeAsync(storeId, e));
        });
        CompletableFuture<Void> allAsync = CompletableFuture
                .allOf(listAsync.toArray(new CompletableFuture[listAsync.size()]));

        CompletableFuture<List<GHNV2CalFeeDetailResponse>> allClientAsync = allAsync.thenApply(v -> listAsync.stream().map(CompletableFuture::join)
                .collect(Collectors.toList()))
                .handle((voidResult, throwable) ->
                        (throwable == null ?
                                listAsync.stream() :
                                listAsync.stream().filter(f -> !f.isCompletedExceptionally()))
                                .map(CompletableFuture::join)
                                .filter(Objects::nonNull)
                                .collect(Collectors.toList()));

        List<GHNV2CalFeeDetailResponse> result = new ArrayList<>();
        try {
            var temp = allClientAsync.get();
            if (!CollectionUtils.isEmpty(allClientAsync.get())) {
                result = temp;
            }
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException(e);
        }
        return result;
    }
```