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