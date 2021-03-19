---
title: Which database should i use
date: 2021-03-17 18:00:26
tags:
    - database
category: 
    - database
---

## CAP Theorem
![CAPTheorem](https://tungexplorer.s3-ap-southeast-1.amazonaws.com/other_file/CAP_Considerations.png)

## 7 Database paradigm
1. Key-value database
- Example: redis, Memcached 
- Pros: fast
- Cons: 
    - limited space
    - no queries
- Best for: 
    - caching
    - pub/sub
    - leaderboards
- Real world: https://github.blog/2009-10-20-how-we-made-github-fast/

2. Wide column
- Ex: HBase, Cassandra
- Pros: 
    - schema less
    - easy scale
- Cons:
    - without joins
- Best for:
    - time-series
    - historical records
    - high write - low read
- Real world: https://netflixtechblog.com/scaling-time-series-data-storage-part-i-ec2b6d44ba39

3. Document 
- Ex: mongoDB, fireStore
- Pros: 
    - schema less
    - relational-ish queries
- Cons: 
    - without joins
- Best for:
    - most apps
    - games
    - iot
- Not ideal for:
    - graphs

4. Relational 
- Ex: MySQL, PostgreSQL
- Best for: most app
- Not ideal for:
    - unstructured data
- 
5. Graph
- Ex: neo4j
- Best for:
    - Graphs
    - Knowledge graphs
    - recommendation engines
- Real world: airbnb
6. Search
- Ex: elasticSearch
- Best for:
    - search engines
    - typeahead
7. Multi model
- Ex: Fauna

