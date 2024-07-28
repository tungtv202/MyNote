---
title: Redis sentinel note
date: 2024-07-28 12:00:26
updated: 2024-07-28 12:00:26
tags:
    - redis
    - redis sentinel
    - sentinel
category: 
    - redis
---

# Redis Sentinel

Redis Sentinel is another model of Redis, and as of now, I am aware of at least the following Redis models:
- **Standalone**: The simplest model with just one Redis node.
- **Master-Replica**: More complex, with one master node and N replica nodes. This model mainly reduces the load on the master node as clients can be configured to read from any node. However, this model does not support failover, meaning if the master node goes down, the system cannot write data.
- **Redis Cluster**: Modern and advanced but requires a minimum of six nodes (3 masters and 3 replicas). It supports failover.
- **Sentinel**: Possibly an older model compared to Redis Cluster. It requires independent Sentinel nodes acting as coordinators, helping clients discover the system and designating a new master node if the old one fails. 

I am still debating whether to choose Redis Cluster or Redis Sentinel. From an end-user perspective, they seem quite similar, but Redis Cluster feels more "trendy". It reminds me of the Kafka architecture I experienced a few years ago. Initially, Kafka had a node called Zookeeper (or bootstrapper, broker, etc.) acting as a coordinator, but later Kafka evolved, and this node was removed or integrated directly into the Kafka worker nodes.

For a production environment, I think deploying one Sentinel node, one master node, and one replica might be sufficient for a small setup. However, the Redis official documentation suggests a simple architecture should include three Sentinel nodes, one master, and two replicas. Their reasoning includes concerns about voting algorithms and the fact that "the more nodes, the better the failover".

## Deployment Experience
Recently, I had an experience deploying Redis Sentinel for a client. I set up a simple Docker Compose lab to run locally. The sample source code is available here:

[Sample Docker Compose with Redis Sentinel](https://github.com/vttranlina/james-project/blob/149595da247dfb915ecb60d239edf627616916ae/server/mailet/rate-limiter-redis/docker-compose-sample/docker-compose-with-redis-sentinel.yml)

### Key Points

- When mounting `sentinel.conf` and `redis.conf` files into Redis, it's best to do it as shown in the Docker entrypoint file. If mounted directly into the volume, Redis will encounter permission issues when it attempts to rewrite these config files during failover events.

## Redis URI Syntax with Lettuce

Refer to the Redis URI syntax when using the Lettuce library:
[Redis URI and Connection Details](https://github.com/redis/lettuce/wiki/Redis-URI-and-connection-details)

There are essentially two types of URLs: `redis:` and `redis-sentinel:`, meaning there is no special URL for clusters or master-replica setups. In some of my labs, clusters and master-replica setups require multiple `redis:` URLs.

Here is an example Redis URL for Sentinel:

```
redisURL=redis-sentinel://secret1@sentinel-1:26379,sentinel-2:26379,sentinel-3:26379?sentinelMasterId=mymaster
```

### Configuration Example
Sample `sentinel.conf` can be found here: [Sentinel Configuration](https://download.redis.io/redis-stable/sentinel.conf)

### Verification Commands

To verify the Redis setup:

#### Master Node
To verify the master node setup, run the following command:
```bash
redis-cli INFO replication
```

Expected output:
```angular2html
role:master
connected_slaves:2
```

#### Replica Nodes
To verify the replica nodes setup, run the following command on each replica node:
`redis-cli -a ${REDIS_PASS} INFO replication`
Expected output:

```angular2html
role:slave
master_host:${REDIS_MASTER_HOST}
master_port:${REDIS_MASTER_PORT}
master_link_status:up
```

#### Sentinel Nodes
To verify the sentinel nodes setup, monitor the logs on the Redis master and replica nodes (enable debug level logging for more details). Then, run the following command on any sentinel node:

`redis-cli -p 26379 -a ${REDIS_PASS} SENTINEL masters`

The sentinel will rewrite the `/usr/local/etc/redis/sentinel.conf` file when discovering the replicas/other sentinel nodes. Then we can check the configuration file to see the discovered nodes.

Run command: `cat /usr/local/etc/redis/sentinel.conf`

The end of the file should look like this:

```
sentinel known-replica mymaster 172.19.0.5 6379
sentinel known-replica mymaster 172.19.0.3 6379
sentinel known-sentinel mymaster 172.19.0.7 26379 bdfe331304c1dc737226deff780a18d38e4f9b55
sentinel known-sentinel mymaster 172.19.0.6 26379 c8ba86a48859ef6329538f71eadcaed30aba638b
```