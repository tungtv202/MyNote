---
title: Java - Implement Quartz
date: 2020-06-03 18:00:26
updated: 2020-06-03 18:00:26
tags:
    - java
    - quartz
    - auto scheduler
category: 
    - java
---

# Tích hợp Quartz vào Spring
![https://miro.medium.com/max/1400/1*TC0WiXrDTkYsLRdT2Sk9mg.png](https://miro.medium.com/max/1400/1*TC0WiXrDTkYsLRdT2Sk9mg.png)
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
- Nếu threadpool = 2, và số job có `fire time` trùng nhau là 1000. Thì tại thời điểm `fire time` 2 schedule sẽ được excute, sau đó 996 schedule còn lại sẽ bị delay xử lý dần dần, chứ không mất
- RISK: nếu time execute > circle time. (Ví dụ cron trigger 5s chạy 1 lần, và time exeute là 8s). Và có N schedule có time execute trùng nhau, thì có vẻ như có 1 local queue được sử dụng tạm thời, để N schedule đều được xử lý hết vòng. Nhưng khi tới 1 threshold nào đó (chưa rõ cách tính threshold), thì N schedule sẽ bị reset time next trigger. Khi  đó quartz sẽ có thông báo lỗi kiểu "Có N schedule bị miss"
![Risk](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/QuartzRisk.PNG)
- Mỗi 1 instance (các instance chạy cùng db), nếu không set name, thì SCHEDULE_NAME = `quartzScheduler`
- Để set tên 
  ```
        org.quartz:
        scheduler:
          instanceName: instance002
  ```
- khi trigger job, job sẽ được chạy trên instance cùng tên với tên SCHEDULE_NAME trong trigger
- trong case các instance cùng tên, khi instance đang trigger job bị shutdown, thì trigger đó sẽ không được chạy trên instance còn lại. Chỉ trừ trường hợp restart lại 1 trong các instance. (Default là như vậy, có thể sẽ khác nếu config khác)