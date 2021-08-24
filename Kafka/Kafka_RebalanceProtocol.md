---
title: Kafka - Rebalance Protocol
date: 2020-07-13 18:00:26
updated: 2020-07-13 18:00:26
tags:
    - kafka
    - rebalance
    - coordinator
category: 
    - kafka
---

## Rebalancing
- When do we rebalance?
    - Member "dies" (doesn't heartbeat for "long" period of time)
    - Member leaves
    - New member joins
    - Topic metada or subscription changes
- How do we discover we need to reblance?
    - While polling 
        - HearbeatResponse (REBALANCE_IN_PROGRESS)
        - CommitOffset (REBALANCE_IN_PROGRESS)
    - Initiate a rebalance by re-joinning
- When we rebalance - stop everything and rejoin
- Sau khi process msg xong, sẽ `revokerd`, sau đó lại `assigned` lại 1 chu kỳ mới.
## Rebalance protocol
- FindCoordinator
- JoinGroup
    - Config: 
        - session.timeout.ms: The timeout used to detect consumer failures when using Kafka's group management facility. The consumer sends periodic heartbeats to indicate its liveness to the broker. If no heartbeats are received by the broker before the expiration of this session timeout, then the broker will remove this consumer from the group and initiate a rebalance
        - max.poll.interval.ms: The maximum delay between invocations of poll() when using consumer group management. This places an upper bound on the amount of time that the consumer can be idle before fetching more records. If poll() is not called before expiration of this timeout, then the consumer is considered failed and the group will rebalance in order to reassign the partitions to another member.
        (https://stackoverflow.com/questions/39730126/difference-between-session-timeout-ms-and-max-poll-interval-ms-for-kafka-0-10)
    - Được `coordinator` sử dụng để kick member ra khỏi group, nếu nó không có phản hồi
- SyncGroup
- Heartbeat
    - Định kỳ consumer gửi `heartbeat` về cho `coordinator` để duy trì session active (heartbeat.interval.ms)
- LeaveGroup
    - Được consumer gửi tới coordinator trước khi stop
    - Sau khi leaveGroup, thì cần thực hiện lại JoinGroup, SyncGroup cho lần sau
## Công dụng Rebalance
- Confluent Schema Registry sử dụng rebalace protocol để chọn leader node
- Kafka Connect sử dụng rebalace protocol để phấn bố các tasks và connectors một cách phù hợp trên các workers node
- Kafka Stream sử dụng rebalace protocol để gán tasks và partitions đến các instances
## Feature
 - Static Membership
    - consumer instance sẽ được định danh bởi `group.instance.id` 
    - Khi sảy ra sự cố tạm thời, làm `transient failures`, thì coordinator sẽ không reblance ngay lập tức cho các consumer khác, mà nó sẽ đợi cho tới khi hết `session timeout` của consumer đang xảy ra lỗi tạm thời. 
    - Vì được đinh danh, nên khi consumer hết lỗi, comeback, sẽ không cần phải yêu cầu joinGroup, lại nữa. Bộ coordinator sẽ trả cache về cho consumer
    - Yêu cầu là  consumer khi lỗi, không được gửi request `leaveGroup`, và nên tăng `sesssion timeout` lên
    - Ưu điểm: tránh việc rebalance không cần thiết
    - Nhược điểm: tăng tính `unavailability` của `partition`, vì `coordinator` phải đợi tới hết session timeout mới phát hiện ra lỗi.
- Incremental Cooperative Rebalancing
    - The Incremental Cooperative Rebalancing attempts to solve this problem in two ways :
        - only stop tasks/members for revoked resources.
        - handle temporary imbalances in resource distribution among members, either immediately or deferred (useful for rolling restart).
    - For doing that, the Incremental Cooperative Rebalancing principal is actually declined into three concrete designs:
        - Design I: Simple Cooperative Rebalancing
        - Design II: Deferred Resolution of Imbalance
        - Design III: Incremental Resolution of Imbalance

## Coding Template
- Quản lý việc commit offset manual
     - Nếu không commitAsync manual chủ động trước
     
```java
@KafkaListener(
            topics = "${kafka.app.backup.product.manual.topic}",
            groupId = "${kafka.app.backup.product.manual.group}",
            concurrency = "${kafka.app.backup.product.manual.thread}"
    )
    public void productManualListen(ConsumerRecord<String, String> record, Consumer<?, ?> consumer) {
        consumer.commitAsync();
        productBackupStrategy.doBackup(backupLogDetailId);
    }
```
- Cấu hình Consumer

```java
@Configuration
@EnableKafka
public class KafkaConfig {
    @Value("${kafka.broker.address}")
    private String kafkaServer;

    @Bean
    public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> kafkaListenerContainerFactory(@Qualifier("json") ObjectMapper objectMapper) {
        ConcurrentKafkaListenerContainerFactory<String, String> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.BATCH);
        factory.getContainerProperties().setAckOnError(true);
        factory.getContainerProperties().setSyncCommits(true);
        factory.setMessageConverter(new StringJsonMessageConverter(objectMapper));
        factory.setErrorHandler(new SeekToCurrentErrorHandlerCustom());
        factory.getContainerProperties().setConsumerRebalanceListener(myConsumerRebalanceListener());
        return factory;
    }

    @Bean
    public CustomRebalance myConsumerRebalanceListener() {
        return new CustomRebalance() {
        };
    }

    @Bean
    public ConsumerFactory<String, String> consumerFactory() {
        return new DefaultKafkaConsumerFactory<>(consumerConfigs());
    }

    @Bean
    public Map<String, Object> consumerConfigs() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaServer);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, org.apache.kafka.common.serialization.StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, org.apache.kafka.common.serialization.StringDeserializer.class);
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, true);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
//        props.put(ConsumerConfig.MAX_PARTITION_FETCH_BYTES_CONFIG, 10 * 1024 * 1024);
//        props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 100);
        props.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, 10 * 1000);
        props.put(ConsumerConfig.REQUEST_TIMEOUT_MS_CONFIG, 10 * 1000);
        props.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, 10 * 1000);
        return props;
    }
}
```

-

```java
public class CustomRebalance implements ConsumerRebalanceListener {
    @Override
    public void onPartitionsRevoked(Collection<TopicPartition> collection) {
        System.out.println("TUNGTUNG revokerd");
    }

    @Override
    public void onPartitionsAssigned(Collection<TopicPartition> collection) {
        System.out.println("TUNGTUNG assigned");
    }
}
```
## Linh tinh
Chưa hiểu tại sao khi cấu hình

```
        props.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG, 5 * 1000);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
```
tức 5s sẽ auto commit, nhưng nếu consumer xử lý msg hết hơn >5s, thì vẫn bị rebalance msg. Trong khi nếu chủ động `onsumer.commitAsync();` thì không bị reblance????
