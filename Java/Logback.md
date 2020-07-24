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
- 
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
.
http://logback.qos.ch/manual/layouts.html