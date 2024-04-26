---
title: Redis cluster note
date: 2024-04-26 12:00:26
updated: 2024-04-26 12:00:26
tags:
    - redis
    - redis cluster
category: 
    - other
---


# Redis cluster

- docker compose lab: https://github.com/vttranlina/redis-cluster-demo
- We need to pay attention to the `cluster-node-timeout` parameter in the configuration file when starting redis-cluster.
For example: `cluster-node-timeout = 60000`, meaning when a node in the cluster goes down, it takes up to 60 seconds for the remaining nodes to confirm that the entire cluster is down. Within 1-60 seconds after node 1 goes down, the remaining nodes still have a normal status.

### 1. redis cluster: 3 node master, 0 node replicas
(a requirement for building a cluster is to have a minimum of 3 master nodes):
Example before any node go down:
- `key1` is stored on `node1`
- `key2` -> `node2`
- `key3` on `node3`.

When `node1` goes down:

- Within the first 1-60 seconds after going down:
    - Clients cannot read or write `key1` (waiting).
    - Clients can read and write `key2` and `key3` normally.
    - When client writes new `key4`:
        - If the "Client-Side Sharding" algorithm on the client side calculates that key4 should be stored on node1, it will be waiting.
        - Otherwise, if it calculates that key4 should be stored on node2 or node3, it will be successfully written (reading afterwards is also successful).
- After 60 seconds, nodes 2 and 3 confirm that the entire cluster is down. At this point, no data can be read or written.

### 2. redis cluster: 3 node master, 3 node replicas
Scenario sample: 

```
Node1 (master) - Node4 (replica)
Node2 (master) - Node5 (replica)
Node3 (master) - Node6 (replica)
```
- When node 1 goes down:
    - first 1-60 seconds: similar to the scenario of 3 master nodes above.
    - After 60 seconds: node4 automatically becomes the master. Reading and writing any data return to normal.


During this time, monitoring the Redis logs, there will be logs like:

```
Cluster state changed: fail
....
Cluster state changed: ok
```
