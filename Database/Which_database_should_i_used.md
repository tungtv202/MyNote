---
title: Which database should i use
date: 2021-03-17 18:00:26
updated: 2021-03-17 18:00:26
tags:
    - database
category: 
    - database
---

## CAP Theorem

![CAP Theorem](https://tungexplorer.s3-ap-southeast-1.amazonaws.com/other_file/CAP_Considerations.png)

## 7 Database Paradigms

### 1. Key-Value Database

- **Examples:** Redis, Memcached
- **Pros:** Fast
- **Cons:**
  - Limited space
  - No queries
- **Best for:**
  - Caching
  - Pub/Sub
  - Leaderboards
- **Real world example:** [How We Made GitHub Fast](https://github.blog/2009-10-20-how-we-made-github-fast/)

### 2. Wide Column

- **Examples:** HBase, Cassandra
- **Pros:**
  - Schema-less
  - Easy to scale
- **Cons:** No joins
- **Best for:**
  - Time-series data
  - Historical records
  - High write, low read workloads
- **Real world example:** [Scaling Time Series Data Storage at Netflix](https://netflixtechblog.com/scaling-time-series-data-storage-part-i-ec2b6d44ba39)

### 3. Document

- **Examples:** MongoDB, Firestore
- **Pros:**
  - Schema-less
  - Relational-ish queries
- **Cons:** No joins
- **Best for:**
  - Most applications
  - Games
  - IoT
- **Not ideal for:**
  - Graphs

### 4. Relational

- **Examples:** MySQL, PostgreSQL
- **Best for:** Most applications
- **Not ideal for:**
  - Unstructured data

### 5. Graph

- **Example:** Neo4j
- **Best for:**
  - Graphs
  - Knowledge graphs
  - Recommendation engines
- **Real world example:** Airbnb

### 6. Search

- **Example:** Elasticsearch
- **Best for:**
  - Search engines
  - Typeahead

### 7. Multi-Model

- **Example:** Fauna
