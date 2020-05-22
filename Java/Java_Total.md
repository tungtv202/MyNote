## Collection Interface 
![CollectionInterface](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/CollectionInterface.PNG)
## SerialVersionUID 
- Là giá trị dùng để định nghĩa thứ tự data của object khi serialize thành byte stream, chúng ta chỉ deserialize object chỉ khi SerialVersionUID của class đúng với SerialVersionUID của instance được lưu trữ.
- Không định nghĩa SerialVersionUID thì sao?
    - Cơ chế của Serializable sẽ tự động tạo SerialVersionUID trong quá trình runtime dựa vào các thuộc tính của class, nếu chúng ta không định nghĩa SerialVersionUID và lưu trữ object. Sau đó nếu chúng ta có một vài thay đổi của class và cơ chế của Serializable sẽ tạo ra một SerialVersionUID khác với SerialVersionUID  của instance đang được lưu trữ, chúng ta sẽ gặp lỗi InvalidClassException khi deserialize object (xem thêm về exception tại đây). Do đó phải luôn luôn nhớ định nghĩa SerialVersionUID cho class khi implement Serializable.
    - Cài đặt warning mặc định của eclipse sẽ cảnh báo “The Serializable class User does not declare a static final SerialVersionUID field of type long” khi chúng ta không định nghĩa SerialVersionUID và suggest chúng ta tạo SerialVersionUID. Thực chất SerialVersionUID được tạo ra bởi serialver tool nằm trong thư mục bin cài đặt Java
## Double Brace
- initialization syntax ({{ ... }}) 
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
- Lưu ý: `initialOffset` phải là số có thật trong kafka, chứ ko phải logic set initialOffset 1 số bất kỳ bé hơn 1 offset nào đó mà mình mong muốn.
