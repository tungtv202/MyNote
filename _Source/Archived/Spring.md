---
title: Spring Framework Note
date: 2021-09-25 18:00:26
updated: 2022-03-06 02:00:26
tags:
    - spring
    - java
category: 
    - java
---

## Spring Framework Note

- Singleton pattern 

## Should I use @Service @Component for Repository/Dao class? 
- If the Repository/Dao class using JDBC, it won't make any difference
- If the Repository/Dao class using JPA/hibernate, it will have a different class exception when throw. If using @Repository, Spring will wrap exception by own exception. 

## Spring Boot Actuator 

- Provides build-in production ready endpoints that can be used for monitoring and controlling your application such as /info, heal/...


## Tiny note
- `@SpringBootApplication` = ( `@Configuration` + `@EnableAutoConfiguration` + `@ComponentScan` )

- Disable particular auto-configuration in spring boot
    - @EnableAutoConfiguration(exclude={DataSourceAutoConfiguration.class})
    - @SpringBootApplication(exclude=DataSourceAutConfiguration.class)



