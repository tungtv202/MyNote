---
title: Kafka - Note 
date: 2019-12-31 18:00:26
updated: 2019-12-31 18:00:26
tags:
    - kafka
    - segment
    - total
categories:
    - kafka
---

## 1. Topics, Partitions and Offsets

- `Topics`: a particular stream of data
    - Similar to a table in a database (without all the constraints).
    - You can have as many topics as you want.
    - A topic is identified by its `name`.
- Topics are split into `partitions`.
    - Each partition is ordered.
    - Each message within a partition gets an incremental id, called `offset`.
- Offset only has meaning for a specific partition.
    - E.g., offset 3 in partition 0 doesn't represent the same data as offset 3 in partition 1.

- Order is guaranteed only within a partition (not across partitions).
- Data is kept only for a limited time by default (one week), but retention can be configured to keep data indefinitely.
- Once the data is written to a partition, `it can't be changed` (immutability).
- Data is assigned randomly to a partition unless a key is provided (more on this later).
- Kafka has no concept of a global position in a topic; positions exist only at the partition level.

## 2. Brokers

- A Kafka cluster is composed of multiple brokers (servers).
- Each broker is identified with its ID (integer).
- Each broker contains certain topic partitions.
- After connecting to any broker (called a `bootstrap broker`), you will be connected to the entire cluster.
- A good number to get started is 3 brokers, but some big clusters have over 100 brokers.
- Note: data is distributed and Broker 103 doesn't have any Topic B data.
- With multiple partitions, a topic’s data is distributed across multiple brokers, and each partition can be replicated to other brokers for fault tolerance.
- A partition itself is never split across brokers; it is always stored as a complete log on each broker that hosts it (Leader or Follower).

## 3. Topic Replication Factor

- Topics should have a replication factor > 1 (usually between 2 and 3).
- This way, if a broker is down, another broker can serve the data.
- Example: Topic-A with 2 partitions and replication factor of 2.
- At any time only ONE broker can be a leader for a given partition.
- Only the leader can accept writes and typically serve reads for a partition.
- The other brokers replicate data from the leader.
- Therefore, each partition has one leader and multiple replicas, a subset of which are called ISR (in-sync replicas).

## 4. Producers

- Producers write data to topics (which are made of partitions).
- Producers fetch cluster metadata to know which broker is the leader for each partition.
- Producers send data directly to the leader broker of the target partition.
- In case of broker failures, producers automatically recover via metadata refresh and retries.

- Producers can choose the acknowledgment level for writes:
  - acks=0: no acknowledgment (possible data loss).
  - acks=1: acknowledgment from leader only (possible data loss).
  - acks=all: acknowledgment from all in-sync replicas (strong durability).

- Producers can send a key with each message.
- If key is null, Kafka uses a sticky partitioner to distribute messages across partitions.
- If a key is provided, all messages with the same key are sent to the same partition.
- Keys are typically used to guarantee ordering for a specific entity (e.g., orderId, truck_id).

## 5. Consumers & Consumer Groups

- Consumers read data from topics (identified by name).
- Consumers fetch cluster metadata to know which broker (partition leader) to read from.
- In case of broker failures, consumers automatically recover via metadata refresh and rebalance.
- Data is read in order within each partition.
- Consumers read data as part of a consumer group (identified by group.id).
- Each consumer within a group reads from exclusive partitions.
- If there are more consumers than partitions, some consumers will be inactive.

## 6. Consumer Offsets

- Kafka stores the offsets of each consumer group.
- Committed offsets are stored in an internal Kafka topic called __consumer_offsets.
- Consumers control when offsets are committed.
- Offsets are typically committed after messages are successfully processed.
- If a consumer dies, another consumer in the same group resumes reading from the last committed offset.

- There are 3 delivery semantics:
  - At most once:
    - Offsets are committed before processing.
    - Message loss is possible if processing fails.
  - At least once (most common):
    - Offsets are committed after processing.
    - Messages may be processed more than once.
    - Processing logic must be idempotent.
  - Exactly once:
    - Supported by Kafka for Kafka-to-Kafka workflows (e.g., Kafka Streams).
    - Kafka-to-external systems require idempotent processing to achieve effectively-once semantics.

## 7. Kafka Broker Discovery

- Any Kafka broker can be used as a bootstrap server.
- Clients only need to connect to one broker to fetch cluster metadata.
- After fetching metadata, clients communicate directly with the appropriate broker leaders.
- Each broker maintains metadata about all brokers, topics, and partitions in the cluster.

## 8. ZooKeeper (Legacy / Historical)

- In older Kafka versions, ZooKeeper was used to manage broker metadata and controller election.
- ZooKeeper helped detect broker failures and metadata changes.
- Kafka stored consumer offsets in ZooKeeper prior to version 0.10.
- ZooKeeper clusters typically run with an odd number of nodes (3, 5, 7).
- ZooKeeper uses a leader-follower model for consistency.

- Modern Kafka versions (with KRaft mode) no longer depend on ZooKeeper.
- Kafka now manages metadata internally using the Raft consensus protocol.

## 9. Kafka Guarantees

- Messages are appended to a partition in the order they are written to that partition.
- Consumers read messages in order within each partition.
- With a replication factor of N, Kafka can tolerate up to N−1 broker failures for a partition, as long as at least one replica remains in sync.
- This is why a replication factor of 3 is a common best practice:
  - Allows one broker to be taken down for maintenance.
  - Allows another broker to fail unexpectedly.
- As long as the number of partitions for a topic remains constant, the same key will always be mapped to the same partition.

## 10. Theory Roundup

![TheoryRoundUp1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/broker_discovery_1.JPG)

```
ref: Udemy - Apache Kafka Series - Learn Apache Kafka for Beginners v2
```

# Kafka - Segment & ...

## Partitions and Segments

- Topics are made of partitions.
- Partitions are stored as a sequence of segment files on disk.
- Only one segment per partition is active and receives new writes.
- Segment rolling is controlled by:
  - log.segment.bytes: maximum size of a segment.
  - log.segment.ms: maximum time a segment remains active before being rolled.

- Each segment consists of:
  - a .log file containing message data.
  - an offset index (.index) mapping offsets to file positions.
  - a time index (.timeindex) mapping timestamps to offsets.

- Kafka uses sparse indexes to efficiently locate data, resulting in near constant-time access.

## unclean.leader.election

// ISR (In-Sync Replicas) is the set of replicas that are alive and sufficiently caught up with the leader.
// Replica = a copy of partition data; ISR = trusted replicas eligible for leader election and acknowledgments.

- If all in-sync replicas (ISR) for a partition are unavailable, but out-of-sync replicas are still alive:
  - By default, Kafka waits for an ISR to come back online (unclean.leader.election=false).
  - This preserves data consistency but makes the partition unavailable.

- If unclean.leader.election=true:
  - Kafka may elect an out-of-sync replica as the new leader.
  - Availability is restored immediately.
  - Data loss can occur because messages missing from the new leader will be discarded.

- This setting improves availability at the cost of durability and consistency.
- It is considered dangerous and should only be enabled when data loss is acceptable.
- Typical use cases include metrics, monitoring, and log collection.

## min.insync.replicas

- min.insync.replicas defines the minimum number of in-sync replicas (including the leader) that must acknowledge a write.
- This setting is only enforced when the producer uses acks=all.
- min.insync.replicas can be configured at the broker level or overridden at the topic level.
- With replication.factor=3, min.insync.replicas=2, and acks=all:
  - Kafka can tolerate one broker failure.
  - If more than one broker is down, producers will receive an error on send.

## 4. Advertised Host Setting

- ![Advertised](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_note/advertised.JPG)

____________________

- When enable.auto.commit=false, auto.commit.interval.ms is ignored.
- Reference Kafka properties: https://jaceklaskowski.gitbooks.io/apache-kafka/kafka-properties.html
  // end
- Hot partition example (common in e-commerce): a single popular product generates ~90% of events.
  • 90% of messages go to 1 partition.
  • Other partitions remain idle.