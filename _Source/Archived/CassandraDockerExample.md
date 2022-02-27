
1. Single datacenter

```yml
version: '3'
services:
  n1:
    image: cassandra:3.11
    networks:
      - cluster
  n2:
    image: cassandra:3.11
    networks:
      - cluster
    environment:
      - CASSANDRA_SEEDS=n1
    depends_on:
      - n1
  n3:
    image: cassandra:3.11
    networks:
      - cluster
    environment:
      - CASSANDRA_SEEDS=n1
    depends_on:
      - n1
networks:
  cluster:
```

2. Multi datacenter

```yml
version: '3'
services:
  n1:
    image: cassandra:3.11
    networks:
      - cluster
    environment:
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=DC1
      - CASSANDRA_RACK=RAC1
  n2:
    image: cassandra:3.11
    networks:
      - cluster
    environment:
      - CASSANDRA_SEEDS=n1
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=DC1
      - CASSANDRA_RACK=RAC2
    depends_on:
      - n1
  n3:
    image: cassandra:3.11
    networks:
      - cluster
    environment:
      - CASSANDRA_SEEDS=n1
      - CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
      - CASSANDRA_DC=DC2
      - CASSANDRA_RACK=RAC1
    depends_on:
      - n1
networks:
  cluster:
```

3. Dockerfile

```
FROM cassandra:3.11
COPY cqlshrc /root/.cqlshrc
```

- `.cqlshrc`

```config
[connection]

;; A timeout in seconds for opening new connections
timeout = 60

;; A timeout in seconds for executing queries
request_timeout = 60
```

Ref: https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cassandra/cassandra-developers.zip