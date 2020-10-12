---
title: Kafka - Use case 
date: 2020-01-02 18:00:26
tags:
    - kafka
    - use case
category: 
    - kafka
---

# Kafka Use case 
## 1. Video Analytics - MovieFlix
- MovieFlix is a company that allows you to watch TV Shows and Movies on demand. The business wants the following capabilities
- Make sure the user can resume the video where they left it off
- Build a user profile in real time
- Recommend the next show to the user in real time
- Store all the data in analytics store
![MovieFlix](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_usecase/movieflix.JPG)
- `show_position` topic:
    - is a topic that can have multiple producers
    - should be highly distributed if high volume > 30 partitions
    - if i were to choose a key, i would choose "user_id"
- `recommendations` topic:
    - the kafka streams recommendation engine may source data from the analytical store for historical training
    - may be a low volume topic
    - if i were to choose a key, i would choose `user_id`

## 2. IOT Example - GetTaxi
- GetTaxi is a company that allows people to match with taxi drivers on demand, right-away. The business wants the following capabilities:
- The user should match with a close by driver
- The pricing should `surge` if the number of drivers are low or the number of user is high
- all the position data before and during the ride should be stored in an analytics store so that the cost can be computed accurately
![gettaxi](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_usecase/gettaxi.JPG)
- `taxi_position, user_position` topics:
    - are topics that can have multiple producers
    - should be highly distributed if high volume > 30 partitions
    - if i were to choose a key, i would choose "user_id","taxi_id"
    - Data is ephemeral and probably doesn't need to be kept for a long time
- `surge_pricing` topic:
    - the computation of surge pricing comes from the Kafka Streams application
    - surge pricing may be regional and therefore that topic may be high volume
    - other topics such as "weather" or "events" etc can be included in the Kafka Streams application

## 3. CQRS - MySocialMedia
- MysocialMedia is a company that allows you people to post images and others to react by using "likes" and "comments". The business wants the following capabilites:
- users should be able to post, like and comment
- users should see the total number of likes and comments per post in real time
- high volume of data is expected on the first day of launch
- users should be able to see "trending" posts
![cqrs](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_usecase/cqrs.JPG)
- responsibilites are `segregated` hence we can call the model CQRS (Command Query Responsibility Segregation)
- Posts
    - are topics that can have multiple producers
    - should be highly distributed if high volume > 30 partitions
    - if i were to choose a key, i would choose "user_id"
    - we probably want a high retention period of data for this topic
- Likes, Comments
    - are topics with multiple producers
    - should be highly distributed as the volume of data is expected to be much greater
    - if i were to choose a key, i would choose "post_id"
- The data itself in Kafka should be formatted as `events`
    - User_123 created a post_id 456 at 2 pm
    - User_234 liked post_id 456 at 3pm
    - User_123 deleted a post_id 456 at 6pm

## 4. Finance application - MyBank
- MyBank is a company that allows real-time banking for it users. It want to deploy a brand new capability to alert user in case of large transactions.
- the transaction data already exists in a database
- thresholds can be defined by the users
- alerts must be sent in real time to the users
![MyBank](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_usecase/myBank.JPG)
- Bank Transactions topics:
    - Kafka Connect Source is a great way to expose data from existing database
    - there are tons of CDC (change data capture) connectors for technologies such as PostgreSQL, Oracle, MySQL, SQLServer, MongoDB etc...
- Kafka Stream application:
    - When a user changes their settings, alerts won't be triggered for past transactions
- User thresholds topics:
    - it is better to send `events` to the topic (User 123 enabled threshold at $1000 at 12pm on July 12th 2018)
    - Than sending the state of the user: (User 123: threshold $1000)

## 5. BigData Ingestion
- It is common to have `generic` connectors or solutions to offload data from Kafka to HDFS, Amazon S3, and ElasticSearch for example
- It is also every common to have Kafka serve a `speed layer` for real time applications, while having a `slow layer` which helps with data ingestions in to stores for later analytics
- Kafka as a front to BigData Ingestion is a common pattern in Big Data to provide an `ingestion buffer` in front of some stores
![Bigdata](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_usecase/bigdata.JPG)

## 6. Logging & Metrics Aggregation
- ![Logging](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/kafka_usecase/logging.JPG)