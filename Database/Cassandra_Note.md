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

## CQL

### 1. Keyspaces

- Create

```SQL
CREATE KEYSPACE keyspace101 WITH REPLICATION  = {
 'class' : 'NetworkTopologyStrategy', 'DC1': 3
} AND DURABLE_WRITES = false;
```

### 2. Tables

- Set the TTL for an entire row

```sql
INSERT INTO table101 (id, token)
VALUES ('id1', 'token2') USING TTL 10800;
``` 

- Set a table-wide, default TTL

```sql
CREATE TABLE reset_tokens (
    id varchar PRIMARY KEY,
    token varchar
) WITH default_time_to_live = 10800;
```

## Table properties

    - comment
    - caching (keys, row_per_partition)
    - read_repair_chance
    - dclocal_read_repair_chance
    - default_time_to_live  (ttls to delete data)
    - gc_grace_seconds  (circle time to gc delete forever data, that make tombstones)
    - bloom_filter_fp_chance
    - compaction
    - compression
    - min/max_index_interval
    - memtable_flush_period_in_ms
    - populate_io_cache_on_flush
    - speculative_retry
    - ...


## Data Type

### 1. Basic Data Types

- Numeric: bigint, decimal, double, float, int, variant
- String: ascii, text, varchar
- Date: timestamp, timeuuid
- Other: boolean. uuid, inet, blob

### 2. Complex Data Types

- `2.1 Set`
    - Create
    ```sql
        CREATE TABLE courses ( 
        id varchar, 
        name static, 
        features set<varchar> static, 
        module_id int, 
        PRIMARY KEY (id, module_id) 
        )
    ```
    - Insert
    ```sql
        INSERT INTO courses (id, features) VALUES ('nodejs-big-picture', {'cc'}); 
    ```
    - Adding to a set
    ```sql
    UPDATE courses SET features = features + {'cc'} WHERE course_id = ‘nodejs-big-picture’;
    ```
    - Removing from a set
    ```sql
    UPDATE courses SET features = features - {'cc'} WHERE course_id = ‘nodejs-big-picture';
    ```
    - Empty
    ```sql
    UPDATE courses SET features = {} WHERE course_id = 'nodejs-big-picture'; 
    ```
- `2.2 List`
    - Create
    ```sql
    CREATE TABLE courses ( 
    id varchar, 
    name static, 
    module_id int, 
    clips list<varchar>, 
    PRIMARY KEY (id, module_id) 
    )
    ```
    - Insert
    ```sql
    INSERT INTO courses (id, module_id, clips) 
    VALUES ('nodejs-big-picture',1,['Course Overview']); 
    ```
    - Adding to a list
    ```sql
    UPDATE courses SET clips = ['Course Introduction'] + clips 
    WHERE course_id = 'nodejs-big-picture' AND module_id = 2; 
    ```
    ```sql
    UPDATE courses SET clips = clips + ['Considering Node.js'] 
    WHERE course_id = 'nodejs-big-picture' AND module_id = 2;
    ```
    - Removing from a list
    ```sql
    UPDATE courses SET clips = clips - [‘Course Overview'] 
    WHERE course_id = ‘nodejs-big-picture‘ and module_id = 1;
    ```
    - Manipulating a list by element id
    ```sql
    UPDATE courses SET clips[2] = ‘What Makes up Node.js?’ 
    WHERE course_id = ‘nodejs-big-picture‘ AND module_id = 2; 
    ```
    ```sql
    UPDATE courses SET clips[2] = ‘What Makes up Node.js?’ 
    WHERE course_id = ‘nodejs-big-picture‘ AND module_id = 2; 
    ```
- `2.3 Map`
    - Create
    ```sql
    CREATE TABLE users ( 
    id varchar, 
    first_name varchar, 
    last_name varchar, 
    password varchar, 
    reset_token varchar, 
    last_login map<varchar,timestamp>, 
    PRIMARY KEY (id) 
    )
    ```
    - Inserting with a map
    ```sql
    INSERT INTO users (id, first_name, last_name, last_login) 
    VALUES ('john-doe', 'John', 'Doe', 
    {'383cc0867cd2': '2015-06-30 09:02:24'}); 
    ```
    - Updating / adding to a map
    ```sql
    UPDATE users SET last_login['383cc0867cd2'] 
    = '2015-07-01 11:17:42' WHERE user_id = 'john-doe';
    ``` 
    ```sql
    UPDATE users SET last_login = last_login + {'7eb0a8997f39': 
    '2015-07-02 07:32:17'} WHERE user_id = 'john-doe';
    ```
    - Removing from a map
    ```sql
    DELETE last_login['383cc0867cd2'] FROM users 
    WHERE id = 'john-doe';
    ```
    ```sql
    UPDATE users SET last_login = last_login - {'7eb0a8997f39'} 
    WHERE id = 'john-doe';
    ```
    - Emptying the entire map
    ```sql
    UPDATE users SET last_login = {}
    WHERE id = 'john-doe';
    ```
    - Collections and TTL
    ```sql
    UPDATE users USING TTL 31536000 
    SET last_login['383cc0867cd2'] = '2015-07-01 11:17:42' 
    WHERE user_id = 'john-doe';
    ```
- `2.4 Tuples`
    - Create
    ```sql
    CREATE TABLE users ( 
    id varchar, 
    first_name varchar, 
    last_name varchar, 
    password varchar, 
    reset_token varchar, 
    last_login map<varchar, 
    frozen<tuple<timestamp,inet>>>, 
    PRIMARY KEY (id) 
    )
    ```

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

## Primary Key and Composite Partition Keys

```sql
CREATE TABLE keyspace101.table2 (
    id varchar PRIMARY KEY,
    name varchar,
    author varchar
)
```

```sql
CREATE TABLE keyspace101.table2 (
    id varchar,
    name varchar,
    author varchar,
    PRIMARY KEY ((id, author))
)
```

## Tombstones

When data is deleted in Cassandra, it isn't just removed immediately from the cluster. A tombstone is written to the
database, marking the data in question as deleted. This tombstone is partitioned data just like any other data written
to the cluster, and this managed accordingly, with hinted handoffs, read repairs everything.      
For example, we have a key space with a replication factor of three, and we delete some data at a consistency level of
quorum. Now let's suppose this right doesn't make it to the third node in a cluster responsible for that token range.
Having the tombstone allows the reed repair process to propagate this tombstone to the outdated node

- property: `gc_grace_seconds` (default is 10 days)
- Note: CAN see a tombstone data by some tools

### Why tombstone? 
- it comes from a use case: when we try to delete some row while having one node in cluster DOWN. 
When that node online comeback, it thinks another node is "missing" some data. It doesn't think that row has been removed. So => maybe data has been re-updated/re-insert again to another node.  => In order to avoid that, Cassandra doesn't remove permanently data, it just marks "flag" to rows - that has been removed.

### When do tombstones cause problems?
- Disk usage
- Read performance - (When we query with a special partition key but has too many rows with same partition key (contains all row has been marked removed flag))

## Other

cql:

```sql
expand on; // select result is row format
expand off; // select result is column format
tracing on; 
tracing off;
```

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

## Difference between partition key, composite key and clustering key?

- Primary Key: Cassandra uses a special type of primary key called a composite key to represent group of related rows, alsoe called "Partitions"
- Primary Key = Partition Key + OPTIONAL clustering columns
- Partition key = it determines the nodes on which rows are stored and itself contains multiple columns 
- Composite column = It controls how data is stored inside the partition


## Static column

it is a special column that is shared by all the rows of a partition. the static column is very useful when we want to share a column with a single value.
- A table that does not define any clustering columns cannot have a static column. 
- You can batch conditional updates to a static column.
- Use the DISTINCT keyword to select static columns. 
- If COMPACT STORAGE is specified when the table is built, static columns are not allowed at this time
- If a column is part of partition key/Clustering columns, it cannot be described as a static column

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