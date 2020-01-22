# Kafka CLI Command

## 1. Install 
### 1.1 Thủ công Linux
```bash
# 1. Download
wget http://mirror.downloadvn.com/apache/kafka/2.4.0/kafka_2.13-2.4.0.tgz

# 2. Giải nén tar zxvf
# 3. Gán giá trị PATH biến môi trường tới đường dẫn /bin của kafka
export PATH=/home/vagrant/kafka_2.13-2.4.0/bin:$PATH

# 4. Chạy zookeeper 
# sửa file config/zookeeper.propertie nếu cần thiết (ví dụ: thay đổi đường dẫn chứa data)
zookeeper-server-start.sh config/producer.properties

# 5. Chạy broker server (bootstrap)
# sửa file config/server.properties để kafka client có thể access vào được
advertised.listeners=PLAINTEXT://192.168.60.4:9092
# thay 192.168.60.4 thành địa chỉ IP của dải mạng dùng để access 
# có thể thay đổi các cấu hình khác, nếu cần (ví dụ thay đổi đường dẫn chứa log tại log.dirs=)

# Run broker server
kafka-server-start.sh config/server.properties
```
- Quick run by nohub
```bash
echo "run zookeeper"
nohup bash zookeeper-server-start.sh config/zookeeper.properties >> /tmp/zookeeper.log 2>&1&

echo "run bootstrap server / broker server"
nohup kafka-server-start.sh config/server.properties >> /tmp/kafkaserver.log 2>&1&
```
### 1.2 Docker 
```bash
# docker hub: https://hub.docker.com/r/bitnami/kafka

# 1. create network
docker network create app-tier --driver bridge

# 2. install zookeeper
docker run --name zookeeper-server -d \
    --network app-tier \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    -p 2181:2181 \
    bitnami/zookeeper:latest

# 3. Install broker/boostrap
# Lưu ý KAFKA_CFG_ADVERTISED_LISTENERS
docker run --name kafka-server -d \
    --network app-tier \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper-server:2181 \
    -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://tungexplorer.me:19092 \
    -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092 \
    -p 19092:9092 \
    bitnami/kafka:latest

```

## 2.Topic 
```bash
# Create topic
kafka-topics.sh --zookeeper 127.0.0.1:2181 --topic first_topic --create --partitions 3 --replication-factor 1
# first_topic = tên của topic, tên này là unique, identity
# --partitions 3  = chỉnh số partitions, không nhập sẽ báo lỗi, số partitions là tùy ý. 
# --replication-factor 1 = chỉnh số replication , không nhập sẽ báo lỗi, nếu chỉ chạy 1 broker thì nên nhập 1

# List
kafka-topics.sh --zookeeper 127.0.0.1:2181 --list

# Detail
kafka-topics.sh --zookeeper 127.0.0.1:2181 --topic first_topic --describe

# Delete
kafka-topics.sh --zookeeper 127.0.0.1:2181 --topic first_topic --delete
```

## 3. Producer
```bash
# Vào console producer
kafka-console-producer.sh --broker-list 127.0.0.1:9092 --topic first_topic
# sau khi vào mode, có thể gõ bất kỳ message nào, cứ enter 1 lần, thì message sẽ được gửi đi. 

# Truyền property
kafka-console-producer.sh --broker-list 127.0.0.1:9092 --topic first_topic --producer-property acks=all

# Trường hợp nhập tên 1 topic mới, mà không được tạo trước đó, thì sẽ tự động tạo tạo topic vừa nhập (có WARN cảnh báo). 
# Topic vừa nhập, có các thông số như partition, replication được chỉnh default như ở trong file config/server.properties

```

## 4. Consumer
```bash
# Vào console consumer
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic first_topic
# Như command trên, không nhập groupID, thì cli sẽ tự động tạo ra 1 groupId mới, unique

# Để show ra các message từ lúc begin (chưa được "mark as read"), thì truyền thêm param --from-beginning
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic first_topic --from-beginning

# Để set groupId cho consumer 
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic first_topic --group my-first-application
# trường hợp các consumer cùng chung group, thì các consumer sẽ được nhận message từ topic 1 cách lần lượt, (round robin)
# trường hợp các consumer khác group, thì với mỗi 1 message, tất cả các consumer đều nhận được message như nhau.
```

## 5. Resetting Offset
```bash
# khi consumer đã nhận được message, thì offset trên mỗi partition được "mark as read" sẽ thay đổi (offset lên giá trị gần nhất)
# Sử dụng reset offset, để khi consumer load lại, có thể call lại các message từ offset chưa được "mark"
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group my-first-application --reset-offsets --to-earliest --execute --topic first_topic
# còn các option khác như:
# --to-datetime
# --by-period
# --to-earliest
# --to-latest
# --shift-by
# --from-file
# --to-current

```

# Kafka Tool
- Kafka không cung cấp WEBUI đi kèm (rabbitmq có cung cấp webui đi kèm)
- Để truy xuất tới kafka, có thể dùng tool Kafka tool (có UI)
![Kafkatool](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/kafka_tool_1.JPG)