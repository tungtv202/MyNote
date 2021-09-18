---
title: Java chat app - use Cassandra, MySQL, Redis, RabbitMQ
date: 2021-09-18 15:44:26
updated: 2021-09-18 15:44:26
tags:
- mysql
- cassandra
- redis
- chat
- rabbitmq
category:
- summary book
---

# Java chat app - use Cassandra, MySQL, Redis, RabbitMQ

Book: [Pro Java Clustering and Scalability - Building Real-Time Apps with Spring, Cassandra, Redis, WebSocket and RabbitMQ](https://www.apress.com/gp/book/9781484229842?utm_campaign=3_pier05_product_page&utm_content=11232017&utm_medium=referral&utm_source=safari&wt_mc=ThirdParty.Safari.3.EPR653.ProductPagePurchase#otherversion=9781484229859)

## Single node

```mermaid
graph TD
U1(User 01 Browser) -- web socket --> C
U2(User 02 Browser) -- web socket --> C 
C((Chat App))
C --> R[(Redis)]
C --> Ca[(Cassandra)]
C --> M[(MySQL)]
```

- MySQL: store user/ user role
- Redis: store chatroom info (Redis Hash)
- Cassandra: store chat message conversation

### Flow

- after the WebSocket connected
- client asks for the connected users and their old messages
- client subscribes to start receiving
  - updates when a user joins or leaves the chat room
  - when a public message is sent
  - when a user receives a private message

## Multinode

1. Problem

- ClientA connect to server 1
- ClientB connect to server 2
- How clientA can connect to clientB?

2. Solution

- Using RabbitMQ as a full external STOMP Broker
- Using the Sticky Session Strategy
  - implementation group: 'org.springframework.session', name: 'spring-session'
  - spring.session.store-type: redis

```mermaid
graph TD
N(Nginx)
N --> C1(Chat app 1)
N --> C2(Chat app 2)
N --> C3(Chat app 3)
C1 --> R[(RabbitMQ STOMP Cluster)]
C2 --> R
C3 --> R
```

```mermaid
graph TD
Re[(Redis Cluster)]
Ca[(Cassandra Cluster)]
My[(MySQL with Replication)]
```

## Code by features

### Private Messages

- Spring will auto transformed to destination
- Example
  - Private dest = `/queue/AG1XX5.private.messages`
  - When send message to user: user123, The destination will be transformed
    into `/queue/AG1XX5.private.messages-user123`
    `org.springframework.messaging.simp.SimpMessagingTemplate#convertAndSendToUser`
