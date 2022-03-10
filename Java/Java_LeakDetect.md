---
title: Java - Resource leak detect by PhantomReference
date: 2022-03-10 18:00:26
updated: 2022-03-10 22:11:00
tags:
    - java
    - leak
    - leak detect
    - phantomreference
category: 
    - java
---

# Code sample - Resource leak detect by java.lang.ref.PhantomReference

Note: "resource" is not only "memory", it can be a any method/blockCode for "dispose/release" somethings.

## PhantomReference mechanism
- like `finalizers`, but more "flexible"
- phantomRef.isEnqueued() method returns true which means that innerObject object has been removed from memory. When innerObject object is removed from memory, phantomRef object will be placed in the queue.

## Code sample

- ResourceFacade

```java
public interface ResourceFacade {

    void dispose();
}
```
- Resource: in realword, it can be a object, that we need monitor

```java
import java.util.concurrent.atomic.AtomicLong;

public class Resource implements ResourceFacade {

    public static AtomicLong GLOBAL_ALLOCATED = new AtomicLong(); 
    public static AtomicLong GLOBAL_RELEASED = new AtomicLong(); 
    
    protected boolean disposed;
    private final long number;
    
    public Resource() {
        number = GLOBAL_ALLOCATED.incrementAndGet();
    }
    
    public synchronized void dispose() {
        if (!disposed) {
            disposed = true;
            releaseResources();
        }
    }

    protected void releaseResources() {
        GLOBAL_RELEASED.incrementAndGet();
    }

    public long number() {
        return number;
    }
}

```

- PhantomHandle: the purpose is wrap `Resource`, this a way to get `Resource` at `PhantomResourceRef` 

```java
public class PhantomHandle implements ResourceFacade {

    private final Resource resource;
    
    public PhantomHandle(Resource resource) {
        this.resource = resource;
    }

    public void dispose() {
        resource.dispose();
    }    
    
    Resource getResource() {
        return resource;
    }
}
```

- PhantomResourceRef
```java
public class PhantomResourceRef extends PhantomReference<PhantomHandle> {

    static boolean isTraceEnabled = true;

    private Resource resource;
    private TraceRecord traceRecord;

    public PhantomResourceRef(PhantomHandle referent, ReferenceQueue<? super PhantomHandle> q) {
        super(referent, q);
        this.resource = referent.getResource();
        if (isTraceEnabled) {
            traceRecord = new TraceRecord(StackWalker.getInstance().walk(s -> s.collect(Collectors.toList())));
        }
    }

    public void dispose() {
        Resource r = resource;
        if (r != null) {
            System.out.println(this.getClass().getSimpleName() + " dispose, number = " + r.number());
            r.dispose();
        }
        if (isTraceEnabled) {
            System.out.println(traceRecord.toString());
        }
    }
}
```

- TraceRecord: Optional, for tracing where instance has been created, but not be invoke disposed

```java

class TraceRecord {
    private final List<StackWalker.StackFrame> stackFrames;

    TraceRecord(List<StackWalker.StackFrame> stackFrames) {
        this.stackFrames = stackFrames;
    }

    @Override
    public String toString() {
        StringBuilder buf = new StringBuilder();
        this.stackFrames.subList(3, this.stackFrames.size()).forEach(stackFrame -> {
            buf.append("\t");
            buf.append(stackFrame.getClassName());
            buf.append("#");
            buf.append(stackFrame.getMethodName());
            buf.append(":");
            buf.append(stackFrame.getLineNumber());
            buf.append("\n");
        });
        return buf.toString();
    }
}
```

- Create resource and track, not only "log" the leak detections, we can alose "auto" dispose Resource 
```java
    private static final Set<PhantomResourceRef> REFERENCES = Collections.synchronizedSet(new HashSet<PhantomResourceRef>());
    public static final ReferenceQueue<PhantomHandle> REFERENCE_QUEUE = new ReferenceQueue<>();

    public static ResourceFacade newResource() {
        Resource resource = new Resource();
        PhantomHandle handle = new PhantomHandle(resource);
        PhantomResourceRef ref = new PhantomResourceRef(handle, REFERENCE_QUEUE);
        REFERENCES.add(ref);
        return handle;
    }

    public static void track() {
        Reference<?> referenceFromQueue;
        while ((referenceFromQueue = REFERENCE_QUEUE.poll()) != null) {
            PhantomResourceRef ref = ((PhantomResourceRef) referenceFromQueue);
            ref.dispose();
            referenceFromQueue.clear();
            REFERENCES.remove(ref);
        }
    }
```

- Testing

```java
    @Test
    public void test() throws InterruptedException {
        ResourceFacade rf = PhantomResourceFactory.newResource();
        rf = null;
        System.gc();
        Thread.sleep(1000);
        PhantomResourceFactory.track();
    }
```

output:
```
PhantomResourceRef dispose, number = 1
```