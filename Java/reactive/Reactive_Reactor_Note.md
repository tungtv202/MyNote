---
title:  Reactive - Reactor Note
date: 2021-02-02 22:00:26
tags:
    - java
    - reactive
    - reactor
    - spring webflux
category: 
    - java
---

# Reactive - Reactor Note

## Hot vs. Cold

- Can using `.share()` for switching cold publisher to hot publisher. Then pipeline-evaluates will not retrigger. But only the elements that are emitted after these new subscriptions`.

```java
Flux<Long> coldTicks = Flux.interval(Duration.ofSeconds(1));
Flux<Long> clockTicks = coldTicks.share();

clockTicks.subscribe(tick -> System.out.println("clock1 " + tick + "s");

Thread.sleep(2000);

clockTicks.subscribe(tick -> System.out.println("\tclock2 " + tick + "s");
``` 

```
Output:
clock1 1s
clock1 2s
clock1 3s
    clock2 3s
clock1 4s
    clock2 4s
clock1 5s
    clock2 5s
clock1 6s
    clock2 6s
```

## How to debug better
- `Hooks.onOperatorDebug();` - Should be using in `dev env`? (spent more resouce?)
- `checkpoint`  

```java
private static void checkpoint() {
        int seconds = LocalTime.now().getSecond();
        Mono<Integer> source;
        if (seconds % 2 == 0) {
            source = Flux.range(1, 10)
                         .elementAt(5)
                         .checkpoint("source range(1,10)");
        }
        else if (seconds % 3 == 0) {
            source = Flux.range(0, 4)
                         .elementAt(5)
                         .checkpoint("source range(0,4)");
        }
        else {
            source = Flux.just(1, 2, 3, 4)
                         .elementAt(5)
                         .checkpoint("source just(1,2,3,4)");
        }
        source.block(); //line 186
```

- `ReactorDebugAgent.init();`

## Reactor Context  
1. Simple   

```java

@Log4j2
@RestController
@SpringBootApplication
public class SimpleApplication {
    public static void main(String[] args) {
        SpringApplication.run(SimpleApplication.class, args);
    }

    private static Scheduler SCHEDULER = Schedulers.fromExecutor(Executors.newFixedThreadPool(10));

    private static <T> Flux<T> prepare(Flux<T> in) {
        return in
                .doOnNext(log::info)
                .subscribeOn(SCHEDULER);
    }

    Flux<String> read() {
        Flux<String> letters = prepare(Flux.just("A", "B", "C"));
        Flux<Integer> numbers = prepare(Flux.just(1, 2, 3));
        return prepare(Flux.zip(letters, numbers).map(tuple -> tuple.getT1() + ':' + tuple.getT2()))
                .doOnEach(signal -> {
                    if (!signal.isOnNext()) {
                        return;
                    }

                    ContextView context = signal.getContextView();
                    Object userId = context.get("userId");
                    log.info("user id for this pipeline stage for data '" + signal.get() + "'  is '" + userId + "'");
                })
                .contextWrite(Context.of("userId", UUID.randomUUID().toString()));
    }

    @GetMapping("/data")
    Flux<String> get() {
        return read();
    }
}

```
- Output    

```log
2021-02-02 21:33:36.088  INFO 22868 --- [           main] o.s.b.web.embedded.netty.NettyWebServer  : Netty started on port(s): 8080
2021-02-02 21:33:36.100  INFO 22868 --- [           main] e.r.learning.context.SimpleApplication   : Started SimpleApplication in 1.908 seconds (JVM running for 3.124)
2021-02-02 21:33:40.467  INFO 22868 --- [pool-1-thread-3] e.r.learning.context.SimpleApplication   : 1
2021-02-02 21:33:40.467  INFO 22868 --- [pool-1-thread-2] e.r.learning.context.SimpleApplication   : A
2021-02-02 21:33:40.469  INFO 22868 --- [pool-1-thread-2] e.r.learning.context.SimpleApplication   : B
2021-02-02 21:33:40.469  INFO 22868 --- [pool-1-thread-2] e.r.learning.context.SimpleApplication   : C
2021-02-02 21:33:40.470  INFO 22868 --- [pool-1-thread-3] e.r.learning.context.SimpleApplication   : A:1
2021-02-02 21:33:40.476  INFO 22868 --- [pool-1-thread-3] e.r.learning.context.SimpleApplication   : user id for this pipeline stage for data 'A:1'  is '9faa8b25-e09e-4028-9e0f-38f98f4264b1'
2021-02-02 21:33:40.493  INFO 22868 --- [pool-1-thread-3] e.r.learning.context.SimpleApplication   : 2
2021-02-02 21:33:40.493  INFO 22868 --- [pool-1-thread-3] e.r.learning.context.SimpleApplication   : 3
2021-02-02 21:33:40.505  INFO 22868 --- [pool-1-thread-4] e.r.learning.context.SimpleApplication   : B:2
2021-02-02 21:33:40.506  INFO 22868 --- [pool-1-thread-4] e.r.learning.context.SimpleApplication   : user id for this pipeline stage for data 'B:2'  is '9faa8b25-e09e-4028-9e0f-38f98f4264b1'
2021-02-02 21:33:40.511  INFO 22868 --- [pool-1-thread-4] e.r.learning.context.SimpleApplication   : C:3
2021-02-02 21:33:40.511  INFO 22868 --- [pool-1-thread-4] e.r.learning.context.SimpleApplication   : user id for this pipeline stage for data 'C:3'  is '9faa8b25-e09e-4028-9e0f-38f98f4264b1'

```

2. Mdc  
- https://github.com/spring-tips/reactor-context/blob/master/src/main/java/com/example/reactorcontext/mdc/MdcApplication.java     
- https://youtu.be/5tlZddM5Jo0

## Reactive Dos and DONTs

- https://youtu.be/0rnMIueRKNU
1. Dont 
- ![Dont1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/dont1.JPG)    
- -> alway `return`     

```java
    static <T> Flux<T> addLogging(Flux<T> flux) {
        return flux
                .doOnNext(it -> System.out.println("Received" + it))
                .doOnError(e -> e.printStackTrace())
    }

    //
    getFlux()
        .transform(flux -> addLogging(flux))
        .subscribe();
```

2. Dont
- side effect are not welcomed
- ![Dont2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/dont2.JPG)
- ![Dont3](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/dont3.JPG)

- use it for heavy computations
- block non-blocking threads
- don't use ThreadLocals  -> dùng `Context`          

```java
      Mono.deferContextual(ctx -> {
            return ctx.get("userId");
        })
                .contextWrite(Context.of("userId", "1111"))
                .subscribe();
``` 

- should not  care about the thread (reactor care)

4. Do - check various operators
- `flatMap` - transform every item `concurrently` into a sub-stream, and join the current and the sub-stream
- `concatMap` - same as flatMap, but one-by-one
- `switchMap` - same as concatMap, but will cancel  the previous sub-stream when a new item arrives
- `flatMapSequential` - same as flatMap, but preserves the order of sub-stream items according to the original stream's order
5. Do - think about the resiliency
- `.timeout(Duration)` - cancel the subscription and fail if no items emitted
- `.retry()/retryWithBackoff()` - retry the subscription on failure
- `.repeatWhenEmpty()` - repeat the subscription when it completes without values
- `.defaultEmpty()` - fallback when empty
- `.onErrorResume()` - fallback on error

6. Do
- use `.checkpoint("something")` to "mark" reactive "milestones"
- read about Hooks.onOperatorDebug()
- use reactor-tools `ReactorDebugAgent`  

## Solution for blocking
- ![solutionForBlocking1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/solutionForBlocking1.JPG)  
- ![solutionForBlocking2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/solutionForBlocking2.JPG)
- ![solutionForBlocking3](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/solutionForBlocking3.JPG)

### Terminology
- Imposter Reactive Method
    - a method returning reactive types, but is implemented synchronously
    - e.g., performing significant work before subscribing
- Blocking Encapsulation
    - hiding knowledge of blocking from the caller
    - e.g., blocking on the proper Scheduler without requiring the caller to do so   

https://youtu.be/xCu73WVg8Ps

- `.subscribeOn(Schedulers.boundedElastic())`
- Bad examples          
- ![BadExample1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/badExample1.JPG)
### Takeaways
- pick the best threading model for each app
- isolate blocking to separate service if/when possible
- otherwise, isolate blocking to separate thread pool
- avoid doing significant work before subscribing
- encapsulate blocking at the lowest level possible
- use `BlockHound` during testing

## `Reactive` for Spring MVC
- https://youtu.be/IZ2SoXUiS7M
- https://github.com/rstoyanchev/reactive-for-webmvc

### Best Practices
- don't mix blocking and non-blocking APIs
- vertical non-blocking slices
- don't put non-blocking code behind synchronous APIs
- compose single, deferred, request handling chain
- don't use `block()`, `subscribe()` and the like
- let spring MVC handle it

## Servlet or Reactive Stacks
- https://youtu.be/Dp_aJh-akkU
- https://github.com/rstoyanchev/demo-reactive-spring
- We can have a hundred threads, thousand threads, but finally, it is limited. 
- With the reactive module, we fixed the number of threads.
- reactive paradigm is not necessarily for every application 

- Reason for WebFlux
    - Gateways, edge services, high trafffic
    - latency, streaming scenarios
    - high concurrency with less hardware resources
    - functional programming model
    - lightweight and transparent (less magic, more control)
    - Immutability
- ![Spring WebFlux flow](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/webFluxFlow.JPG)    

- ![Spring MVC flow](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/reactor/note/mvcFlow.JPG) 
