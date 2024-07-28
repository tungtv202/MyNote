---
title: Rate Limiting Algorithm
date: 2022-02-14 12:00:26
updated: 2022-02-14 12:00:26
tags:
    - rate limiting
    - algorithm
category: 
    - other
---

# Rate Limiting Algorithm

1. Token Bucket
2. Leaking Bucket
3. Fixed Window counter
4. Sliding window log
5. Sliding window counter

## Token bucket
Idea:
- There are a few tokens in a bucket.
- When a request comes, a token has to be taken from the bucket for it to be processed. If there is no token available in the bucket, the request will be rejected and the requester has to retry later.
- The token bucket is also refilled per time unit.

2 part:
- refiller: interval put new tokens to bucket  
  (condition: current tokens in bucket + add tokens <= bucket capacity)
- request processor: checking “enough tokens” for requests

Ex:
- request rate: 10 request/hour
- refill rate: 1 request/min

![TokenBucket](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/rate_limiting/tokenBucketEx1.png)

Problem?
- rate limit =  1000/hour, refill rate = 10/second
- consumers can has a 1000 accept requests/second when bucket full. But then request 1001th is rejected
- If we want to stable outflow rate is needed?

## Leaky Bucket

- similar to the Token Bucket
- except that requests are processed at a fixed rate

![Leaky Bucket](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/rate_limiting/LeakyBucketEx1.png)


Problem
Q: What happens if queues full and bucket still NOT full?
A : Requests are discarded (or leaked).

### Compare Leaky Bucket vs Token Bucket:
- Token Bucket:
    - Can send Large bursts can faster rate
    - Not suitable for some use cases (stable outflow rate is needed)
- Leaky Bucket:
    - Requests are processed at a fixed rate (suitable for use cases that a stable outflow rate is needed)
    - There are two parameters in the algorithm (queue + bucket). It might not be easy to tune them properly


## Fixed Window counter

- divides the timeline into fix-sized time windows
- assign a counter for each window
- each incoming request increments the counter for the window
- once the counter reaches the pre-defined threshold,
  new requests are dropped until a new time window starts

Ex:
- window size such as 60 or 600 seconds...
- the windows are typically defined by the floor of the current timestamp,
  so 10:00:06 with a 60 second window length, would be in the 10:00:00 windo

![Fixed Window Counter](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/rate_limiting/FixedWindowCounter.png)

Problem?
- rate limit =  10 request/min
- send 10 request at 2:00:59 → Acceptable
- send 10 request at 2:01:01 → Acceptable
- Duration(2:01:01, 2:00:59) = 2 seconds
- Finally, 10+10=20 request/ 2 seconds has been acceptable

=> Edge problem

Cons?
- Spike in traffic at the edges of a window could cause more requests than the allowed quota to go though
- if many consumers wait for a reset window, they may stampede your API at the same time at the top of the hour.


## Sliding window log

- The algorithm keeps track of request timestamps. (log for each consumer request)
- When a new request comes in, remove all the outdated timestamps
  (Outdated timestamps are defined as those older than the start of the current time window )
- Add timestamp of the new request to the log
- If the log size is the equal or lower than the allowed count, a request is accepted.
  Otherwise, it is rejected

![Sliding window log](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/rate_limiting/SlideWindowLog1.png)

Pros?
- very accurate
- not suffer from the boundary conditions of fixed windows

Cons?
- consumes a lot of memory (even if a request is rejected, its timestamp might still be stored in memory)
- expensive to compute (add/remove log, sort…)

## Sliding window counter

- A hybrid approach that combines the low processing cost of the fixed window algorithm,
  and the improved boundary conditions of the sliding log algorithm.
- Sliding Window tries to fix “edge problem” by taking the previous counter into account

Explain it with an example:
- rate limit = 10/minute
- 9 requests in window [00:00, 00:01]
- 5 requests in window [00:01, 00:02]
- For a request 6th arrives at 00:01:15, which is at 25% position of window [00:01, 00:02]
- Calculate the request count by the formula: 9 x (1 - 25%) + 5 = 11.75 > 10 => reject
- If 6th request arrives at 00:01:30
  9x50% + 5 = 9.5 < 10 => accept

Note:
- ec = previous counter * ((time unit - time into the current counter) / time unit) + current counter
- This is still not accurate because it assumes that the distribution of requests in previous window is even, which may not be true. (But better than Fixed Window)

![Sliding window counter](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/rate_limiting/SlidingWindowCounter1.png)


## Bonus
- https://github.com/mokies/ratelimitj
- https://www.quinbay.com/blog/understanding-rate-limiting-algorithms
