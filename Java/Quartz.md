# Tích hợp Quartz vào Spring
## Use case
- Dùng trong case có nhiều schedule, mà lịch chạy schedule là dynamic
- Ví dụ:
    - Mỗi 1 endUser có  1 lịch schedule chạy 1 task vụ bất kỳ khác nhau. 
    - Lên schedule gửi mail phỏng vấn ứng viên với calendar chuẩn bị trước
## Tích hợp
### 1. Config
- Thư viện
```xml
 <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-quartz</artifactId>
  </dependency>
```
- config .yml
```yml
spring:
  datasource-main:
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
    jdbcUrl: jdbc:sqlserver://0.0.0.0:1433;databaseName=SchemaName
    username: user
    password: passs
    leakDetectionThreshold: 0
    connectionTimeout: 30000
  quartz:
    job-store-type: jdbc
    properties:
      org.quartz:
        threadPool.threadCount: 2
        jobStore:
          isClustered: false
          driverDelegateClass: org.quartz.impl.jdbcjobstore.MSSQLDelegate
```
- Sử dụng jdbc để persistance các job, scheduler
- Lưu ý trường hợp sử dụng MSSQL, cần khai báo `driverDelegateClass`
- Cần tạo các table phục vụ cho QUARTZ. Query create table ứng với mỗi RDBMS: [https://github.com/quartz-scheduler/quartz/tree/master/quartz-core/src/main/resources/org/quartz/impl/jdbcjobstore](https://github.com/quartz-scheduler/quartz/tree/master/quartz-core/src/main/resources/org/quartz/impl/jdbcjobstore)

- ScheduleBuilder
    - Mỗi 1 job là 1 schedule
    - Có 4 loại:
        - CalendarIntervalScheduleBuilder: calendar. (ví dụ set lịch gửi mail phỏng vấn ứng viên)
        - CronScheduleBuilder: cron job sử dụng cron expresssion. Ví dụ set lịch chạy backup định kỳ hàng tuần của mỗi end user
        - SimpleScheduleBuilder: loại basic nhất, chỉ cần set "StartAt" = thời gian muốn chạy job
        - DailyTimeIntervalScheduleBuilder

### 2. Sử dụng
- 2 phần cơ bản:
    - Khai báo, tạo scheduler
    - Execute job 
- a). Khai báo/ tạo scheduler
```java
@Autowired
private  Scheduler scheduler;
//
        final var quartJobKey = UUID.randomUUID().toString();
        JobDetail jobDetail = JobBuilder.newJob(BackupQuartzJob.class)
                .withIdentity(quartJobKey, schedule.jobGroupName())
                .withDescription("Scheduler backup : " + userId)
                .storeDurably()
                .build();

        Trigger trigger = TriggerBuilder.newTrigger()
                .forJob(jobDetail)
                .withIdentity(jobDetail.getKey().getName(), schedule.triggerGroupName())
                .withDescription("Trigger backup : " + userId)
                .withSchedule(CronScheduleBuilder.cronSchedule(schedule.cronExpression()))
                .build();
        scheduler.scheduleJob(jobDetail, trigger);
```
- jobDetail có thể `.setJobData()` là 1 `JobDataMap`. (cho bên Job Excute lôi ra dùng)
- `BackupQuartzJob.class` là class để execute job
- b) Execute job 
```java
@Component
public class BackupQuartzJob extends QuartzJobBean {


    @Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
        System.out.println("TUNG exe: " + new Date());
    }
}
```
- c) Delete job
```java
scheduler.deleteJob(new JobKey(storeConfig.getQuartzJobName(), storeConfig.getQuartzJobGroup()));
```
## Other
- `scheduler` default support sẵn Transactional
- Nếu có 1000 scheduler có cùng cron expression, nhưng lại chỉ có thread pool executer = 4. Vậy 996 scheduler còn lại có chạy ko?
- Trường hợp total time run hết scheduler > time circle. Tức là scheduler cũ chưa chạy xong, lại tới lịch scheduler mới, vậy thứ tự ưu tiên là gì? có xảy ra case 1 scheduler mãi mãi ko bao giờ được execute ko