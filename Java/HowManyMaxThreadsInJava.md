---
title: Java - How many max threads we can create?
date: 2022-04-19 22:00:26
updated: 2022-04-19 22:00:26
tags:
    - java
    - thread
category: 
    - java
---

# How many max threads we can create in Java?

## My PC info

```
OS: Ubuntu 20.04.4 LTS x86_64 
Kernel: 5.13.0-39-generic 
Packages: 2837 (dpkg), 18 (snap) 
Shell: zsh 5.8 
DE: GNOME 
WM: Mutter 
CPU: AMD Ryzen 5 5600G with Radeon Graphics (12) @ 3.900GHz 
GPU: AMD ATI 04:00.0 Device 1638 
Memory: 6860MiB / 27949MiB 
```

## Java code

```java
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class HowManyMaxThreadWeCanCreate {

    public static void main(String[] args) throws InterruptedException {
        int numberOfTasks = 2000000;
        System.out.println("HeapSize start maxMemory " + formatSize(Runtime.getRuntime().maxMemory()));
        CountDownLatch latch = new CountDownLatch(numberOfTasks);

        for (int i = 1; i <= numberOfTasks; i++) {
            int finalI = i;
            new Thread(() -> {
                System.out.println(finalI + " task is started in : " + Thread.currentThread().getName());
                try {
                    TimeUnit.SECONDS.sleep(1000);
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }
                System.out.println(finalI + " task is finished in : " + Thread.currentThread().getName());
                latch.countDown();
            }).start();
        }
        latch.await();
    }

    public static String formatSize(long v) {
        if (v < 1024) return v + " B";
        int z = (63 - Long.numberOfLeadingZeros(v)) / 10;
        return String.format("%.1f %sB", (double) v / (1L << (z * 10)), " KMGTPE".charAt(z));
    }
}
```

## Result

- `32571` threads has been created, after that I got a error

```log
[7,278s][warning][os,thread] Failed to start thread - pthread_create failed (EAGAIN) for attributes: stacksize: 1024k, guardsize: 0k, detached.
#
# There is insufficient memory for the Java Runtime Environment to continue.
# Native memory allocation (mmap) failed to map 16384 bytes for committing reserved memory.
# An error report file with more information is saved as:
# /home/tungtv/workplace/1_STUDY/Study101/hs_err_pid78874.log
[7,279s][warning][os,thread] Attempt to deallocate stack guard pages failed (0x00007f5ac2584000-0x00007f5ac2588000).
[thread 78875 also had an error]
OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x00007f50f74b9000, 16384, 0) failed; error='Not enough space' (errno=12)
Exception in thread "main" java.lang.OutOfMemoryError: unable to create native thread: possibly out of memory or process/resource limits reached
	at java.base/java.lang.Thread.start0(Native Method)
	at java.base/java.lang.Thread.start(Thread.java:798)
	at me.tungexplorer.study.reactor.HowManyMaxThreadWeCanCreate.main(HowManyMaxThreadWeCanCreate.java:30)
OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x00007f5ac2584000, 16384, 0) failed; error='Not enough space' (errno=12)
[7,827s][warning][os,thread] Attempt to deallocate stack guard pages failed (0x00007f568e9f7000-0x00007f568e9fb000).
```

- I tried to increase heap size (by setting Xmx), but maybe it is not a reason
- How can I check threads running in the system (note: os threads, NOT machine threads)

bash: 
```bash
ps -eo nlwp | tail -n +2 | awk '{ num_threads += $1 } END { print num_threads }'
```
    - When normal, thread count from 1000 -> 2000. 
    - When I tried to run the Java app, the thread increased to + ~30k. After Java exit, the threads count came back to normal

- Maximum number of threads per process in Linux?

```bash
cat /proc/sys/kernel/threads-max
# (My Computer is `223043`, my friend computer is `126578`)
````
 
- How Much Memory Does a Java Thread Take?
    - ~1KB
```bash
java -XX:+PrintFlagsFinal -version | grep ThreadStackSize  
     intx CompilerThreadStackSize                  = 1024                                   {pd product} {default}
     intx ThreadStackSize                          = 1024                                   {pd product} {default}
     intx VMThreadStackSize                        = 1024                                   {pd product} {default}
openjdk version "11.0.14.1" 2022-02-08
OpenJDK Runtime Environment (build 11.0.14.1+1-Ubuntu-0ubuntu1.20.04)
OpenJDK 64-Bit Server VM (build 11.0.14.1+1-Ubuntu-0ubuntu1.20.04, mixed mode, sharing)
```