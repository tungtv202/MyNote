---
title: Java - JVM Internal
date: 2020-08-10 18:00:26
tags:
    - jvm internal
    - java
category: 
    - java
---


![https://blog.jamesdbloom.com/images_2013_11_17_17_56/JVM_Internal_Architecture_small.png](https://blog.jamesdbloom.com/images_2013_11_17_17_56/JVM_Internal_Architecture_small.png)
- Việc mapping giữa Thread trong Java và Thread của OS được thể hiện trong Hotspot JVM. Sau khi chuẩn bị đủ state của 1 java thread (thread-local storage, allocation buffer, synchronization object, stack, programe counter) thì Native Thread được tạo. (native thread là OS thread)
- Native Thread sẽ được `reclaim` sau khi Java Thread `terminates`.
- Hệ điều hành chịu trách nhiệm lập lịch cho các thread, và gửi chúng cho CPU đang `available` 
- Native thread sẽ được khởi tạo khi Java thread được gọi `run()` method.
- Sau khi method `run()` được chạy xong (return), Native Thread sẽ confirm vs JVM về việc terminated, khi đó tất cả các resource được sử dụng ở cả Native Thread và Java Thread sẽ được `released`
- Các JVM Thread được chạy background: 
    - VM Thread: 
    - Periodic task thread
    - GC Thread
    - Compiler Thread
    - Signal dispatcher Thread
## Mỗi Thread sẽ gồm các thành phần sau
- `Program Counter`: có nhiệm vụ `counter` cho CPU, và lưu vị trí của code đã được bytes (). Thường thì PC sẽ tăng. 
- `Stack`: 
    - Giữ frame khi method được chạy trên Thread đó
    - Frame mới sẽ được tạo và thêm vào stack (ngăn xếp LIFO). Và sẽ bị remove khi method trả về kết quả. Hoặc xảy ra Exception ??
    - Frame objects được phân bổ trong Heap mà không cần phải liền kề
- `Native Stack`: không phải JVM nào cũng hỗ trợ 
- `Stack Rétrictions`
    - Stack có thể dynamic, hoặc fixed size
    - Nếu thread yêu cầu stack lớn hơn => StackOverflowError
    - Nếu thread yêu cầu frame mới và không đủ bộ nhớ => OutOfMemoryError
- `Frame`: được tạo và thêm vào top của stack cho mỗi `method invocation`. Sẽ được xóa khi method return. Thành phần:
    - local variable array
    - return value
    - operand stack
    - reference to runtime constant pool for class of the current method
- `Local Variables Array`: boolena, byte, char, long, short, int, float, double...
- `Operand Stack`
- `Dynamic Linking`

## Shared Between Threads
- `Heap`: Array và Object không bao giờ lưu trên stack bởi vì frame được thiết kế là không thay đổi size sau khi đã được tạo. Frame chỉ lưu trữ con trỏ tới object và mảng trên heap. Heap được sử dụng để `allocate` class instance, và mảng khi runtime.
- `Memory Management`
    - Object và Arrays sẽ không bao giờ được `de-allocated` , trừ khi bị GC gọi.
    - Typically this works as follows:
        - New objects and arrays are created into the young generation
        - Minor garbage collection will operate in the young generation. Objects, that are still alive, will be moved from the eden space to the survivor space.
        - Major garbage collection, which typically causes the application threads to pause, will move objects between generations. Objects, that are still alive, will be moved from the young generation to the old (tenured) generation.
        - The permanent generation is collected every time the old generation is collected. They are both collected when either becomes full.
- `Non-Heap Memory`:
    - Permanent Generation
    - Code Cache
- `Just In Time (JIT) Compilation`

[https://blog.jamesdbloom.com/JVMInternals.html](https://blog.jamesdbloom.com/JVMInternals.html)      
[http://tutorials.jenkov.com/java-concurrency/thread-signaling.html](http://tutorials.jenkov.com/java-concurrency/thread-signaling.html)
________________________________
## Some Note
JVM - JAVA VIRTUAL MACHINE
1. LIFE CYCLE
- source -> javac -> bytecode -> classloader -> interpreter -> JIT -> optimized natived code
2. JAVAC
- convert source code into byte code
- check
- simple optimizations
3. BYTECODE
![https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/jvm/bytecode.JPG](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/jvm/bytecode.JPG)
4. CLASS
- meta info: java version, file format
- type info: access flags, name, superclass, interfaces
- content: fields, method, signatures, bytecode
5. CLASSLOADER
- dynamically loads classes 
- hierarchies
6. CLASSLOADING PHASES
- loading -> reads class file
- linking
    - verifying -> verifies bytecode correctness
    - preparing -> allocates memory
    - resolving -> links with classes, interfaces fields, methods
- initializing -> static initializers
7. INTERPRETER
- template interpreter
- detect the critical hot spots in the program
8. JIT
- Just In Time
- compiles methods into native code
- client C1 / client C2
- runs up to 20 times faster
9. JIT OPTIMIZATIONS 
- inlining
- loop unrolling
- escape analysis (scalar replacement)
- dead-code elimination
- lock elision
- osr
10. TIERED COMPILATION 
- LEVELS:
    - 0: interpreter code
    - 1: Simple C1 compiled code
    - 2: Limited C1 compiled code
    - 3: Full C1 compiled code 
    - 4: C2 compiled code
11. THREADS
- direct mapping with native OS thread
- scheduling and dispatching delegated to OS
- application (user) threads
- maintenance threads: GC, compiler, etc
12. SYNCHRONIZATION
- described in Java Memory Model
- extremely hard to understand
13. MEMORY BLOCKS
- PC register
- frame 
- stack
14. MEMORY LAYOUT
![https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/jvm/memory_Layout.JPG](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/jvm/memory_Layout.JPG)
15. GARBAGE COLLECTOR
- cleans memory
- important performance factor
- vector algorithm 
- stop the world in safepoints
16. GC ALGORITHMS
- serial
- parallel
- Concurrent Mark sweep
- G1
