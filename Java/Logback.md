---
title: Java - Logback
date: 2020-06-09 18:00:26
updated: 2020-06-09 18:00:26
tags:
    - log
    - logback
category: 
    - java
---


# Cấu hình Logback.xml trong Spring
## 1. Template
- 1

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>

    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    <include resource="org/springframework/boot/logging/logback/file-appender.xml"/>
    <include resource="org/springframework/boot/logging/logback/console-appender.xml"/>
    <timestamp key="today" datePattern="yyyy-MM-dd"/>
    <property name="LOG_FILE" value="my-application"/>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} %-5p ${PID:- } --- [%t] %c : %L: %m%n%wEx</pattern>
        </encoder>

        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>${LOG_PATH}/${LOG_FILE}-${HOSTNAME}-%d{yyyy-MM-dd}.%i.gz</fileNamePattern>
            <maxFileSize>50MB</maxFileSize>
            <maxHistory>30</maxHistory>
        </rollingPolicy>

    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="FILE"/>
    </root>
</configuration>
```
- 2 

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property name="defaultPattern" value="%date [%thread] %highlight(%-5level) %cyan(%logger{15}) [%file : %line] %msg%n" />

    <appender name="Sentry" class="io.sentry.logback.SentryAppender">
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>WARN</level>
        </filter>
    </appender>

    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>${defaultPattern}</pattern>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="STDOUT"/>
        <appender-ref ref="Sentry"/>
    </root>
</configuration>
```
- 3

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml"/>
    <jmxConfigurator/>
    <springProperty name="SENTRY_LOG_LEVEL" source="sentry.log.level" defaultValue="OFF"/>
    <property name="defaultPattern" value="%date %level [%thread] %logger{10} [%file : %line] %msg%n" />

    <appender name="FILE" class="ch.qos.logback.core.FileAppender">
        <file>service.log</file>
        <encoder>
            <pattern>${defaultPattern}</pattern>
        </encoder>
    </appender>
    <appender name="Sentry" class="io.sentry.logback.SentryAppender">
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>${SENTRY_LOG_LEVEL}</level>
        </filter>
    </appender>

    <logger level="DEBUG" name="service" additivity="false">
        <appender-ref ref="CONSOLE"/>
    </logger>
    <logger level="DEBUG" name="exception" additivity="false">
        <appender-ref ref="CONSOLE"/>
    </logger>

    <root level="DEBUG">
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```
- 4. Set biến theo springProfile

```xml
<springProfile name="staging">
		<property name="LOG_ROOT" value="/sapo-logs" />
	</springProfile>
	<springProfile name="live">
		<property name="LOG_ROOT" value="/sapo-logs" />
	</springProfile>
	<springProfile name="debug">
		<property name="LOG_ROOT" value="sapo-logs" />
	</springProfile>
	<appender name="FILE" class="ch.qos.logback.core.FileAppender">
		<file>${LOG_ROOT}/app-name/service.log</file>
		<encoder>
			<pattern>"%date" %level [%thread] %logger{10} [%file : %line] %msg%n
			</pattern>
		</encoder>
	</appender>
```


## 2. Chú thích
```java
    @Bean
    public Logger logger() {
        return new Slf4jLogger("exception");
    }
```

```xml
<logger name="com.lankydan.service.MyServiceImpl" additivity="false" level="debug">
  <appender-ref ref="STDOUT" />
</logger>
```
- Có thể cấu hình trong file .yml hoặc .properties

```properties
logging.level.root=info
logging.level.com.lankydan.service=error
logging.path=logs
logging.file=${logging.path}/log.log
logging.pattern.file=%d{dd-MM-yyyy HH:mm:ss.SSS} [%thread] %-5level %logger{36}.%M - %msg%n
logging.pattern.console=  
```
- ref: http://logback.qos.ch/manual/layouts.html

## 3. AWS CloudWatch Logback Apender
- Maven
```xml
        <dependency>
            <groupId>ca.pjer</groupId>
            <artifactId>logback-awslogs-appender</artifactId>
            <version>1.4.0</version>
        </dependency>
```
- Logback.xml
    - Lưu ý cần set 2 env để credential
    AWS_ACCESS_KEY=123456;
    AWS_SECRET_KEY=123456;
```xml
<appender name="ASYNC_AWS_LOGS1" class="ca.pjer.logback.AwsLogsAppender">
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>INFO</level>
        </filter>
        <logStreamName>topic.test1</logStreamName>
        <logRegion>ap-east-1</logRegion>
        <logGroupName>/sapo/web-pos-channel-v2</logGroupName>
        <layout>
            <pattern>%date %level [%thread] %logger{10} [%file : %line] %msg%n</pattern>
        </layout>
    </appender>
```
Ref: https://github.com/pierredavidbelanger/logback-awslogs-appender
## 4. Loki log Appender
- maven
```xml
        <dependency>
            <groupId>com.github.loki4j</groupId>
            <artifactId>loki-logback-appender</artifactId>
            <version>0.4.0</version>
        </dependency>

```
- logback.xml
```xml
    <appender name="LOKI" class="com.github.loki4j.logback.LokiJavaHttpAppender">
        <url>http://192.168.13.249:3100/loki/api/v1/push</url>
        <batchSize>100</batchSize>
        <batchTimeoutMs>10000</batchTimeoutMs>
        <encoder class="com.github.loki4j.logback.JsonEncoder">
            <label>
                <pattern>app=tung-test-can-remove-whenever,host=${HOSTNAME},level=%level</pattern>
            </label>
            <message>
                <pattern>l=%level h=${HOSTNAME} c=%logger{20} t=%thread | %msg %ex</pattern>
            </message>
            <sortByTime>true</sortByTime>
        </encoder>
    </appender>
```
Ref: https://github.com/tungtv202/loki-logback-appender
