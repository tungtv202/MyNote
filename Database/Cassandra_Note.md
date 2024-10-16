---
title: Cassandra Note
date: 2021-04-11 12:04:26
updated: 2021-04-11 12:04:26
tags:
    - cql
    - cassandra
    - database
category: 
    - database
---

## Data Type

### 3. User Defined Types

```sql
CREATE TYPE person (name varchar, id varchar); 
```

```sql
CREATE TABLE courses ( 
 id varchar, 
 author frozen<person> static, 
 // ... 
 clips list<frozen<clip>>, 
 module_id int, 
 // ... 
 PRIMARY KEY (id, module_id) 
)
```

### 4. Data with JSON

- Insert
    - normal:
    ```sql
    INSERT INTO courses 
    (id, module_id, author, clips) 
    VALUES (‘nodejs-big-picture’, 1, 
    { 
    name: ‘Paul O''Fallon', 
    id: ‘paul-ofallon' 
    }, [{ 
    name: ’Course Overview’, 
    duration: 70 
    }] 
    );
    ```
    - Use json
    ```sql
    INSERT INTO courses JSON '{ 
    "id": "nodejs-big-picture", 
    "module_id": 1, 
    "author": { 
    "name": "Paul O’Fallon", 
    "id": "paul-ofallon" }, 
    "clips": [{ 
    "name": "Course Overview", 
    "duration": 70 
    }] 
    }' 
    ```
- Selecting

```sql
SELECT JSON * FROM courses;
```

```sql
SELECT DISTINCT id, name, toJson(released) FROM courses;
```

## Materialized Views

![MaterializedView](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/MaterializedViews.JPG)

## Secondary Indexes

- If `dont secondary index`, you cant query on `collection` column

```sql
CREATE TABLE users ( 
 id varchar, 
 first_name varchar, 
 last_name varchar, 
 company varchar, 
 tags set<varchar>, 
 // ... 
 PRIMARY KEY (id) 
); 
```

```sql
CREATE INDEX ON users(tags)
```

```sql
SELECT * FROM users WHERE tags CONTAINS 'java';
```

## Batches

```
BEGIN BATCH 
INSERT INTO courses (id, tags) 
VALUES (‘nodejs-big-picture‘, 
 {‘developer', 'javascript', 'node.js', 'open-source'}); 
 
INSERT INTO course_tags (tag, course_id) 
VALUES (‘developer’,'nodejs-big-picture'); 
// ... etc. 
APPLY BATCH;
```

## Lightweight Transactions

```
1. Prepare ! Promise 
2. Read ! Results 
3. Propose ! Accept 
4. Commit ! Ack
```

## User Defined Functions

- Use `hourly`

```sql
SELECT asTimeStr(duration, false) 
FROM courses 
WHERE id = ‘advanced-javascript’
``` 

    - Input: 24936 => Output: 6h 55 m

- Defined
  ![DefinedFunction](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/DefinedFunction.JPG)

## Tombstones

When data is deleted in Cassandra, it isn't immediately removed from the cluster. Instead, a tombstone is written to the database, marking the data in question as deleted. This tombstone is partitioned data, just like any other data written to the cluster, and it is managed accordingly with hinted handoffs, read repairs, and more.

For example, consider a keyspace with a replication factor of three, and we delete some data at a consistency level of quorum. Now let's suppose this write doesn't make it to the third node in the cluster responsible for that token range. Having the tombstone allows the read repair process to propagate this tombstone to the outdated node.

- Property: `gc_grace_seconds` (default is 10 days)
- Note: You can see tombstone data using certain tools.

### Why Tombstones?

Tombstones address a specific use case: when we try to delete a row while one node in the cluster is down. When that node comes back online, it might think another node is "missing" some data. It doesn't realize that the row has been deleted. As a result, the data could be re-updated or re-inserted into another node. To avoid this, Cassandra doesn't permanently remove data; it just marks the rows with a "flag" indicating they have been removed.

### When Do Tombstones Cause Problems?

- **Disk Usage:** Tombstones can accumulate and consume disk space.
- **Read Performance:** When querying with a specific partition key that includes too many rows marked as deleted, read performance can degrade.


## Counters

Counters are a special data type in Cassandra since dealing with them in a distributed environment requires special
care. Counters must live in tables by themselves other than the primary keys they also carry with them. Some added
overhead as they rely on read before, right.

## Multi-row Partitions

1. Composite partition keys and Clustering keys
   ![Key](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/Key.JPG)
2. Static columns

```sql
CREATE TABLE courses ( 
 id varchar, 
 name varchar STATIC, 
 module_id int, 
 module_name varchar, 
 PRIMARY KEY (id, module_id)
);
```

3. Time Series Data

- TimeUUID Data Type
    - Example: `45b94a50-12e5-11e5-9114-091830ac5256`
    - The number of 100 ns intervals since UUID epoch
    - MAC address
    - Clock sequence number to prevent duplicates
- cql ex:

```sql
CREATE TABLE course_page_views ( 
 course_id text, 
 view_id timeuuid, 
 PRIMARY KEY (course_id, view_id) 
) WITH CLUSTERING ORDER BY (view_id DESC);
```

- now

```sql
CREATE TABLE course_page_views ( 
 course_id text, 
 view_id timeuuid, 
 PRIMARY KEY (course_id, view_id) 
) WITH CLUSTERING ORDER BY (view_id DESC);
```

- dateOf / unixTimestampOf

```sql
SELECT course_id, dateOf(view_id) 
FROM course_page_views WHERE course_id = ‘advanced-python‘;
```

- minTimeuuid / maxTimeuuid

```sql
SELECT dateOf(view_id) 
FROM course_page_views 
WHERE course_id = ‘advanced-python' 
AND view_id >= maxTimeuuid('2019-11-01 00:00+0000') 
AND view_id < minTimeuuid(‘2019-12-01 00:00+0000')
```

4. Bucketing Time series data

```sql
CREATE TABLE course_page_views ( 
 bucket_id text, 
 course_id text, 
 view_id timeuuid, 
 PRIMARY KEY ((bucket_id, course_id), view_id) 
) WITH CLUSTERING ORDER BY (view_id DESC);
```

## Storing Data in Cassandra

All data stored in Cassandra is associated with a token

## Snitches

???

## Replication Strategies

![Cassandra_Terminology](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/Cassandra_terminology.JPG)

1. SimpleStrategy

- Used in dev env or single data center cluster
- CQL ex

```sql
CREATE KEYSPACE keyspace101 with replication =
{'class': 'SimpleStrategy', 'replication_factor' : 3}
```

`replication_factor : 3` = asking Cassandra to store three copies of all the partitions in all the tables written to
the cluster, in this keyspace

2. NetworkTopologyStrategy

- CQL ex

```sql
CREATE KEYSPACE keyspace102 with replication =
{'class': 'NetworkTopologyStrategy', 'DC1' : 3, 'DC2': 1}
```

storing 4 copies of the data for each partition in each table/in the keyspace. `BUT` 3 in DC1, and 1 in DC2

## Tunable Consistency

- `Hinted Handoff` is used to handle transient failures
- (Write Consistency + Read Consistency) > Replication Factor
- Command set consistency level
    - multi-dc: ` consistency local_one;`
    - single-dc: `consistency quorum;`

1. Read
   ![Tunable Consistency Reads](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/TunableConsistency_Reads.JPG)

- Read Repair
    - What happens when 1 node with old data, and 2 node with good data?
    - Then, the third node will return a digest that does not match the other two nodes.
    - The coordinator node will then read the full data from all three nodes, determine the correct data
    - Write correct data back to the node that's in error

2. Write

- Coordinator (node receive write statement) will wait to receive an ack of the other node before returning a positive
  response to the collar
  ![Tunable Consistency - Writes](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/TunableConsistency_Writes.JPG)

- Hinted Handoff
    - What happens if one of those writes fails?
    - Cassandra uses a strategy called a hinted handoff to help in these situations
    - The data is written down on the coordinator node
    - Then the coordinator know tries repeatedly to deliver the data

3. Consistency with multiple data centers

- EACH_QUORUM
- LOCAL_QUORUM
- LOCAL_ONE

## Difference between Partition Key, Composite Key, and Clustering Key

- **Primary Key:** Cassandra uses a special type of primary key called a composite key to represent a group of related rows, also called "Partitions".
- **Primary Key = Partition Key + OPTIONAL Clustering Columns**
- **Partition Key:** It determines the nodes on which rows are stored and can contain multiple columns.
- **Composite Key:** It controls how data is stored inside the partition.

## Static Column

A static column is a special column that is shared by all the rows of a partition. The static column is very useful when we want to share a column with a single value.

- A table that does not define any clustering columns cannot have a static column.
- You can batch conditional updates to a static column.
- Use the DISTINCT keyword to select static columns.
- If `COMPACT STORAGE` is specified when the table is built, static columns are not allowed.
- If a column is part of the partition key or clustering columns, it cannot be described as a static column.


## How to quick warm up cassandra after start for development?

- Run with argument `JVM_OPTS=-Dcassandra.skip_wait_for_gossip_to_settle=0 -Dcassandra.initial_token=1`
Example in docker-compose file 
```yaml
version: '3'

services:
  cassandra:
    image: cassandra:4.1.3
    ports:
      - "9042:9042"
    healthcheck:
      test: ["CMD", "cqlsh", "-e", "describe keyspaces"]
      interval: 3s
      timeout: 20s
      retries: 5
    environment:
      - JVM_OPTS=-Dcassandra.skip_wait_for_gossip_to_settle=0 -Dcassandra.initial_token=1
```

## TWCS vs STCS

### TimeWindowCompactionStrategy (TWCS)

**Use Case:**

TWCS is specifically designed for time-series data, where data is constantly appended and older data becomes less frequently accessed.

**How It Works:**

TWCS divides data into windows based on time intervals (e.g., hours, days, or weeks). Within each window, data is organized using Size-Tiered Compaction (STCS). When a window becomes older than a specified time threshold, it is compacted into a single SSTable (Sorted String Table). This helps in efficiently managing time-series data with minimal disk I/O.

**Advantages:**

- Efficient for time-series data.
- Reduces read amplification for recent data.
- Older data is less frequently compacted, reducing compaction overhead.

### SizeTieredCompactionStrategy (STCS)

**Use Case:**

STCS is a general-purpose compaction strategy that can be used for a wide range of workloads.

**How It Works:**

STCS organizes data into SSTables based on their size. When the number of SSTables in a given level exceeds a threshold, compaction is triggered. SSTables are merged into larger SSTables, and data is compacted based on size.

**Advantages:**

- Simplicity and good performance for various workloads.
- Effective for write-intensive workloads where data is rapidly changing.

**Disadvantages:**

- Less efficient for time-series data since it doesn't consider time-based access patterns.

### Choosing Between TWCS and STCS

The choice between TWCS and STCS depends on your data and access patterns:

- If you are dealing with time-series data, such as log data, sensor readings, or financial data, TWCS is typically a better choice. It optimizes storage and access patterns for time-based data.
- For general-purpose workloads or write-intensive applications, STCS can work well. It's simple to configure and is suitable for scenarios where data isn't primarily organized by time.

In some cases, a mixed strategy approach is used, where you might use TWCS for recent data and STCS for historical or less frequently accessed data to strike a balance between efficiency and simplicity.

Ultimately, the choice of compaction strategy should align with your specific use case and performance requirements. It's important to benchmark and monitor your Cassandra cluster to ensure that the chosen strategy meets your needs.
