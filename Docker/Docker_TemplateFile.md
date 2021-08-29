---
title: Docker - Template File
date: 2020-02-10 18:00:26
updated: 2020-02-10 18:00:26
tags:
    - docker
    - template
category: 
    - docker
---

# For `Springboot`

## Dockerfile

- Template 1

```Dockerfile
FROM openjdk:8-jre
RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
RUN mkdir /data
WORKDIR /data
ADD myapp.jar /data/myapp.jar

ENV springprofiles="" \
    MAXRAMIFNOLIMIT=4096

ENTRYPOINT MAXRAM=$(expr `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` / 1024 / 1024) && \
           MAXRAM=$(($MAXRAM>$MAXRAMIFNOLIMIT?$MAXRAMIFNOLIMIT:$MAXRAM))m && \
           echo "MaxRam: $MAXRAM" && \
           java -XX:MaxRAM=$MAXRAM -Djava.security.egd=file:/dev/./urandom -jar -Dspring.profiles.active="$springprofiles" myapp.jar

#when "-XX:+UseCGroupMemoryLimitForHeap" isn't experimental anymore, you can use the following
#ENTRYPOINT java -XX:+UseCGroupMemoryLimitForHeap -Djava.security.egd=file:/dev/./urandom -jar -Dspring.profiles.active="$springprofiles" myapp.jar	
# To prevent delays caused by the random number generator, use /dev/./urandom instead of /dev/random	   
EXPOSE 8080
```

- Template 2
    - Dockerfile

```Dockerfile
FROM openjdk:8-jdk-alpine
ENV TZ=Asia/Ho_Chi_Minh
ENV JAVA_OPTS="-Xmx128M -Xms128M"
ADD run.sh run.sh
RUN sh -c 'chmod +x /run.sh'
ADD target/lib lib
ADD target/applications.jar applications.jar
CMD ["/run.sh"]
```

- run.sh

```bash
#!/bin/sh
export HOST_NAME=`hostname`
case $SPRING_PROFILES_ACTIVE in
	local)
		exec java -Xmx128M -Djava.security.egd=file:/dev/./urandom -jar applications.jar
	;;
	staging)
		exec java -Xmx1G -Djava.security.egd=file:/dev/./urandom -jar applications.jar
	;;
	live)
		exec java -Xmx4G -Djava.security.egd=file:/dev/./urandom -jar applications.jar
	;;
esac
```

- Build .jar

```bash
docker build -t springio/gs-spring-boot-docker .
```

## Ref

- https://spring.io/guides/gs/spring-boot-docker/
- What exactly does `-Djava.security.egd=file:/dev/./urandom` do when containerizing a Spring Boot application?
    - The purpose of that security property is to speed up tomcat startup. By default the library used to generate
      random number in JVM on Unix systems relies on /dev/random. On docker containers there isn't enough entropy to
      support /dev/random. See Not enough entropy to support /dev/random in docker containers running in boot2docker.
      The random number generator is used for session ID generation. Changing it to /dev/urandom will make the startup
      process faster.
      -> [Link](https://stackoverflow.com/questions/58853372/what-exactly-does-djava-security-egd-file-dev-urandom-do-when-containerizi)