---
title: Kafka - Note 
date: 2019-12-31 18:00:26
tags:
    - kafka
    - segment
    - total
category: 
    - kafka
---

## 1. Topics, partitions and offsets
- `Topics`: a particular stream of data
    - Similar to a table in a database (without all the constrints)
    - You can have as many topics as you want
    - A topic is identified by its `name`
- Topics are split in `partitions`
    - Earch partition is ordered
    - Each message within a partition gets an incremental ids, called `offset` 
- ![Kafka partitions](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/topics_1.JPG)
- Offset only have a meaning for a specific partition
    - E.g. offset 3 in partition 0 doesn't represent the same data as offset 3 in partition I
- Order is guaranteed only within a partition (not across partitions)
- Data is kept only for a limited time (default is one week)
- Once the data is written to a partition, `it can't be changed` (immutability)
- Data is assigned randomly to a partition unless a key is provided (more on this later)
- Thư mục chứa các partitions ở tại ../data/kafka

## 2. Brokers 
- A Kafka cluster is composed of multiple brokers (servers)
- Each broker is identified with its ID (integer)
- Each broker contains certain topic partitions
- After connecting to any broker (called a `bootstrap broker`), you will be connected to the entire cluster
- A good number to get started is 3 brokers, but some big clusters have over 100 brokers    
![Broker1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/btoker_1.JPG)
- Note: data is distributed and Broker 103 doesn't have any Topic B data

## 3. Topic replication factor
- Topics should have a replication factor > I (usually between 2 and 3)
- This way if a broker is down, another broker can serve the data
- Example: Topic-A with 2 partitions and replication factor of 2    
![Topic_replication_factor1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/topic_replication_factor_2.JPG)
- `At any time only ONE broker can be a leader for a given partition`
- `Only that leader can receive and serve data for a partition`
- The other brokers will synchronize the data
- Therefore each partition has one leader and multiple ISR (in-sync replica)

## 4. Producers
- Producers write data to topics (which is made of partitions)
- Producers automatically know to which broker and partition to write to 
- In case of Broker failures, Producers will automatically recover  
![Producer1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/producer_1.JPG)
- Producers can choose to receive acknowledgment of data writes:
    - `acks=0`: Producer won't wait for acknowledgment (possible data loss)
    - `acks=l`: Producer will wait for leader acknowledgment (limited data loss)
    - `acks=all`: Leader + replicas acknowledgment (no data loss)
- Producers can choose to send a `key` with the message (string, number, etc...)
- If key=null, data is sent round ro bin (broker 101 then 102 then 103...)
- If a key is sent, then all messages for that key will always go to the same partition
- A key is basically sent if you need message ordering for a specific field (ex: truck_id)
![ProducerMessageKey1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/producer_message_key_1.JPG)

## 5. Consumers & Consumer Groups
- Consumers read data from a topic (identified by name)
- Consumers know which broker to read from
- In case of broker failures, consumers know how to recover
- Data is read in order `within each partitions`
![Consumer1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/btoker_1.JPG)
- Consumers read data in consumer groups
- Each consumer within a group reads from exclusive partitions
- If you have more consumers than partitions, some consumers will be inactive
![Consumer2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/consumer_2.JPG)
- If you have more consumers than partitions, some consumers will be inactive
![Consumer3](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/consumer_3.JPG)

## 6. Consumer Offsets
- Kafka stores the offsets at which a consumer group has been reading
- The offsets committed live in a Kafka topic named `__consumer_offsets`
- When a consumer in a group has processed data received from Kafka, it should be committing the offsets
- If a consumer dies, it will be able to read back from where it left off thanks to the committed consumer offsets!
![Offset1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/offset_1.JPG)
- Consumers choose when to commit offsets.
- There are 3 delivery semantics:
    - At most once:
        - offsets are committed as soon as the message is received.
        - If the processing goes wrong, the message will be lost (it won't be read again)
    - At least once (usually preferred):
        - offsets are committed after the message is processed.
        - if the processing goes wrong, the message will be read again
        - This can result it duplicate processing of messages. Make sure your processing is `idempotent` (i.e. processing again the messages won't impact your systems)
    - Exactly once:
        - can be achieved for Kafka => Kafka workflows using Kafka Streams API
        - for Kafka => External System workflows, use an idempotent consumer.

## 7. Kafka Broker Discovery
- Every Kafka broker is also called a `bootstrap server`
- That means that `you only need to connect to one broker`, and you will be connected to the entire cluster.
- Each broker knows about all brokers, topics and partitions (metadata)
![Discovery1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/broker_discovery_1.JPG)

## 8. Zookeeper
- Zookeeper manages brokers (keeps a list of them)
- Zookeeper helps in performing leader election for partitions.
- Zookeeper sends notifications to Kafka in case of changes (e.g. new topic, broker dies, broker comes up, delete topics, etc...)
- `Kafka can't work without Zookeepr`
- Zookeeper by design operates with an odd number of servers (3,5,7)
- Zookeeper has a leader (handle writes) the rest of the servers are followers (handle reads)
- (Zookeepr does NOT store consumer offsets with Kafka > v0.10)
![Zookeeper1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/zookeeper_1.JPG)

## 9. Kafka Guarantees
- Messages are appended to a topic-partition in the order they are sent
- Consumers read messages in the order stored in a topic-partition
- With a replication factor of N, producers and consumers can tolerate up to N-I brokers being down
- This is why a replication factor of 3 is a good idea:
    - Allows for one broker to be taken down for maintenance
    - Allows for another broker to be taken down unexpectedly
- As long as the number of partitions remains constant for a topic (no new partitions), the same key will always go to the same partition.

## 10. Theory Roundup
![TheoryRoundUp1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/broker_discovery_1.JPG)

```
ref: Udemy - Apache Kafka Series - Learn Apache Kafka for Beginners v2
```


# Kafka - Segment & ...
## 1. Partitions and Segments
- Topics are made of partitions
- Partitions are made of segments (files)
![Segment](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/segment2.JPG)
- Only one segment is `ACTIVE` (the one data is being written to)
- Two segment settings:
    - log.segment.bytes: the max size of a single segment in bytes
    - log.segment.ms: the time Kafka will wait before committing t he segment if not full
- Segments come with two indexes (files):
    - An offset to position index: allows Kafka where to read to find a message
    - A timestamp to offset index: allows Kafka to find messages with a timestamp
- Therefore, Kafka knows where to find data in a constant time

## 2. unclean.leader.election
- if all your In Sync Replicas die (but you still have out of sync replicas up), you have the following option:
    - Wait for an ISR to come back online (default)
    - Enable `unclean.leader.election=true` and start producing to non ISR partitions
- if you enable `unclean.leader.election=true`, you improve availability, but you will lose data because other messages on ISR will be discarded.
- Overall this is a very dangerous setting and its implication must be understood fully before enabling it
- Use cases include: metrics collection, log collection, and other cases where data loss is somewhat acceptable, at the trade-off of availability

## 3. min.insync.replicas
- Acks=all must be used in conjunction with `min.insync.replicas`
- `min.insync.replicas` cam ne set at the broker or topic level (override).
- `min.insync.replicas=2` implies that at least 2 brokers that are ISR (including leader) must respond that they have the data
- That means if you use `replication.factor=3, min.insync=2, acks=all`, you can only tolerate I broker going down, otherwise the producer will receive an exception on send.

## 4. Advertised Host Setting
- ![Advertised](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/advertised.JPG)

____________________
- khi set `enable.auto.commit` = false, thì `auto.commit.interval.ms` không được xét tới
- Tham khảo các properties: https://jaceklaskowski.gitbooks.io/apache-kafka/kafka-properties.html
// end