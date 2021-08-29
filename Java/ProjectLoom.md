---
title: Java - Project Loom
date: 2021-08-19 18:00:26
updated: 2021-08-19 18:00:26
tags:
    - java
    - concurrency
    - project loom
    - fiber
    - virtual thread
category: 
    - java
---

# Project Loom

## Why

- Can't have a million Thread with traditional way. (Normally, number of threads in 2_000-10_000). If lager, we will get
  the OutOfMemory, and JVM stack is expensive
- Reactive is hard to study, reading, and debug

## Virtual Threads

- Make the blocking is very cheap. Over 23 million virtual threads in 16 GB of memory
- Way1

```
Thread thread = Thread.startVirtualThread(runnable);
```

- Way2

```java
Thread thread = Thread.builder()
   .virtual()
   .name(taskname)
   .task(runnable)
   .build();
```

-
Example: [https://horstmann.com/unblog/2020-12-05/dailyImages/ImageProcessor.java](https://horstmann.com/unblog/2020-12-05/dailyImages/ImageProcessor.java)

### VirtualThread.getState()

| VirtualThread State  | Thread State  |
|---|---|
| NEW  | NEW   |
|  STARTED, RUNNABLE | RUNNABLE  |
| RUNNING  | if mounted, carrier thread state else RUNNABLE  | 
| PARKING, YIELDING  |  RUNNABLE | 
| PINNED, PARKED, PARKED_SUSPENDED | WAITING  | 
|  TERMINATED | TERMINATED  | 

## Structured concurrency

## Note

- Don't use `pool` in virtualThread. If using ExecutorService, Loom will create new thread for each task. In Loom, you
  are encouraged to use a separate executor service for each task set.
- We can create virtual thread pool with deadline
