---
title: Java - Code Application expose Metric for Prometheus
date: 2020-02-05 18:00:26
updated: 2020-02-05 18:00:26
tags:
    - java
    - prometheus
    - metric
category: 
    - java
---

# Code Application expose Metric for Prometheus
## 1. Solution
2 cách
- Dùng `micromiter` -> [SourceCode](https://github.com/tungtv202/micromiter-prometheus)
- Dùng `prometheus-client` -> [SourceCode](https://github.com/tungtv202/prometheus-client-sdk)

## 2. Note
### 2.1 Prometheus Metric Type
Có 4 type
- Counter
    - When
        - you want to record a value that only goes up
        - you want to be able to later query how fast the value is increasing (i.e. it’s rate)
    - Use Case
        - request count
        - tasks completed
        - error count
- Gauges
    - When
        - you want to record a value that can go up or down
        - you don’t need to query its rate
    - Use Case
        - memory usage
        - queue size
        - number of requests in progress
- Histograms
    - When
        - you want to take many measurements of a value, to later calculate averages or percentiles
        - you’re not bothered about the exact values, but are happy with an approximation
        - you know what the range of values will be up front, so can use the default bucket definitions or define your own
    - Use Case
        - request duration
        - response size
- Summaries
    - When
        - you want to take many measurements of a value, to later calculate averages or percentiles
        - you’re not bothered about the exact values, but are happy with an approximation
        - you don’t know what the range of values will be up front, so cannot use histograms
    - Use Case
        - request duration
        - response size

### 2.2 Note for code
- Đổi port endpoint metric, độc lập với port webservice logic. Nếu không có khai báo này thì sẽ chạy chung port 8080

    ```properties
    server.port=8080
    management.server.port=8090
    ```
- All metrics are exposed at `/actuator/prometheus`
- Khai báo MetricFilter
    - Cách 1: tạo bean `MeterFilter`
    
    ```java
        @Bean
        public MeterFilter meterFilter() 
    ```
    - Cách 2: khai báo trong file `application.properties`
    ```properties
    management.metrics.enable.jvm=false
    ```
- Lưu ý việc cập nhật metric được chạy ở 1 process khác với endpoint metric. (tức endpoint metric sẽ trả về kết quả đã được tính toán ở 1 process khác trước đó ).  
Ex `BatchJobMetric` class file
- Chú ý `MeterRegistry`

    ```java
        @Override
        public void trackTimerMetrics(String metricName, String... tags) {
            Timer timer = meterRegistry.timer(metricName, tags);
            sampleStore.get().stop(timer);
        }

        @Override
        public void trackCounterMetrics(String metricName, double value, String... tags) {
            meterRegistry.counter(metricName, tags).increment(value);

        }
    ```
- Với kiểu metric `Gauges`, cần chú ý tới việc khai báo ref giá trị metric. Code example

```java
public class MailLagMetricJob implements CommandLineRunner {
    private static int DELAY_QUERY_SECOND = 1;
    private AtomicInteger totalMailIsSendingMetric = new AtomicInteger();
    private AtomicInteger totalMailNotSentMetric = new AtomicInteger();

    @Autowired
    private MailOutboxDao _mailOutboxDao;

    @Autowired
    private MeterRegistry meterRegistry;

    @Override
    public void run(String... args) throws Exception {
        while (true) {
            totalMailIsSendingMetric.set(_mailOutboxDao.totalMailIsSending());
            totalMailNotSentMetric.set(_mailOutboxDao.totalMailNotSent());
            meterRegistry.gauge("mail.is-sending", totalMailIsSendingMetric);
            meterRegistry.gauge("mail.is-not-sent", totalMailNotSentMetric);
            Thread.sleep(DELAY_QUERY_SECOND * 1000);
        }
    }
}
```

## 3. Ref
- [Youtube về metric type + demo dùng prometheus-client](https://www.youtube.com/watch?v=nJMRmhbY5hY)
- [Blog về metric type + demo dùng prometheus-client = ](https://tomgregory.com/the-four-types-of-prometheus-metrics/)
- [Hình ảnh về các prometheus-type, nhìn ảnh trực quan](https://blog.pvincent.io/2017/12/prometheus-blog-series-part-2-metric-types/)
- [@Medium code demo dùng micromiter](https://medium.com/@mejariamol/spring-boot-app-monitoring-micrometer-prometheus-registry-590723a9ae0a)
- [Trang chủ micromiter về prometheus](https://micrometer.io/docs/registry/prometheus#_counters)
