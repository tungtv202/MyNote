## ThreadLocal
- Tư tưởng là mỗi thread, sẽ có 1 "vùng nhớ" riêng để chứa dữ liệu, khi các method ở các class khác nhau, được chạy trong cùng 1 thread, sẽ lấy được giá trị ở "vùng nhớ" đó.
=> Ví dụ có thể áp dụng trong case muốn tạo ra 1 Context, thay vì phải truyền các giá trị thông qua Parameter.
- Thread nào lấy được dữ liệu của thread đó, nên có thể áp dụng trong việc thread safe
- Cần cẩn thận khi sử dụng kèm vs ThreadPool, vì có thể sẽ xảy ra tình huống, 1 task mới, được chạy bởi 1 Thread trong "thread pool", thì nó sẽ lấy được dữ liệu cũ, do một task khác
chạy trước đó, bởi chính Thread đấy.
### Code example
- InheritableThreadLocal: 
    - sử dụng thằng này để các ChildThread được tạo bởi ParentThread, có thể sử dụng chung "vùng nhớ" với ParentThread
    - các ChildThread

```java
public static void main(String[] args) {

        ThreadLocal<String> threadLocal = new ThreadLocal<>();
        InheritableThreadLocal<String> inheritableThreadLocal =
                new InheritableThreadLocal<>();

        Thread thread1 = new Thread(() -> {
            System.out.println("===== Thread 1 =====");
            threadLocal.set("Thread 1 - ThreadLocal");
            inheritableThreadLocal.set("Thread 1 - InheritableThreadLocal");

            System.out.println(threadLocal.get());
            System.out.println(inheritableThreadLocal.get());

            Thread childThread = new Thread(() -> {
                System.out.println("===== ChildThread =====");
                System.out.println(threadLocal.get());
                System.out.println(inheritableThreadLocal.get());
                inheritableThreadLocal.set("TUNG");
                System.out.println(inheritableThreadLocal.get());
            });

            Thread childThread2 = new Thread(() -> {
                try {
                    TimeUnit.SECONDS.sleep(3);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("===== ChildThread2 =====");
                System.out.println(threadLocal.get());
                System.out.println("Check: " + inheritableThreadLocal.get());
            });
            childThread.start();
            childThread2.start();

            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(inheritableThreadLocal.get());
            inheritableThreadLocal.set("TUNG2");
        });

        thread1.start();

//        Thread thread2 = new Thread(() -> {
//            try {
//                Thread.sleep(3000);
//            } catch (InterruptedException e) {
//                e.printStackTrace();
//            }
//
//            System.out.println("===== Thread2 =====");
//            System.out.println(threadLocal.get());
//            System.out.println(inheritableThreadLocal.get());
//        });
//        thread2.start();
    }
```