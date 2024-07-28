---
title: DDos, Stress test, distribution test với Jmeter, Docker, AWS ECS
date: 2020-11-08 18:00:26
updated: 2020-11-08 18:00:26
tags:
    - jmeter
    - aws
    - ecs
    - test
category: 
    - stories
---

# DDos, Stress Test, Distribution Test with Jmeter, Docker, AWS ECS

## 1. Introduction

This article notes the steps I experienced with the combination of these three tools to stress test my web app system.
The initial goal was to perform performance tests and stress tests from the perspective of an end user (from the outside in). 
While it may not achieve true DDos or distribution testing due to limited infrastructure resources, 
the architecture is aimed towards that goal. I hope that by sharing my experiences, this guide will help you save time in
finding solutions for stress testing and performance testing.

Some basic knowledge you should have if you intend to follow this guide:

- Basic knowledge of Jmeter
- Basic knowledge of Docker
- Basic knowledge of AWS ECS

## 2. Quick Scenario

- Jmeter: A tool that supports stress testing. You can write a script to access a website (or an API) and perform actions (GET, POST, etc.). It supports CPU, thread, loop iterations, and exports test results. It also supports exporting a test plan file (`.jmx`), suitable for running on servers.
- Docker: Using Jmeter's `.jmx` file to build a container.
- AWS ECS: A service from AWS to run containers. This will provide the infrastructure resources to run the script (CPU, RAM, network). Using ECS allows easy scaling without managing individual server nodes. You only run tasks when testing, saving costs. You can fully utilize ECS by creating multiple clusters across different regions. Besides ECS, you can use other services like K8s or Docker Swarm.

![Overview](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ddos_overview.jpg)

## 3. Step by Step

## 3.1 Writing the Jmeter Script

- Download Jmeter: https://jmeter.apache.org/download_jmeter.cgi
    - Requires Java (minimum Java 8)
    - Provides a UI. Simply download, extract, and run the `.jar` file in the /bin directory.
    - When installing on Linux, be aware of the version (default on Ubuntu is 2.x, which is outdated and may cause script errors).
- Writing the script (not detailing how to use Jmeter here)
    - Jmeter has a recording mode
    - Scenario: Using https://webhook.site/ as the target website for testing. This site generates a unique URL for you, and any requests to this URL will be visualized on the webhook.site dashboard.
    - Example `jmx` file: https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/test.jmx
    - I also wrote a script to create orders on a shopping site (no captcha required) and it worked fine, showing Jmeter's versatility.

![jmetertool](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/jmeter_tool.JPG)

## 3.2 Testing the `.jmx` Script

- Run the script using the UI tool on your PC for simplicity. After execution, check webhook.site for messages to confirm success.
  ![webHook.site](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/webhook.site.JPG)
- Run the script on a Linux server using CLI:

```bash
bash ~/jmeter/apache-jmeter-5.3/bin/jmeter.sh -n -t ~/jmeter/01/test.jmx -j tmp1.log -l tmp2.xml
```

    - `test.jmx` is the test plan file
    - `tmp1.log` is the log file
    - `tmp2.xml` is the result file (showing HTTP request statuses like 200, 404, 403)
    - Use `-n` for non-GUI mode on the server

## 3.3 Dockerfile

- After testing the CLI and everything works fine, build the Dockerfile:

```Dockerfile   
FROM openjdk:8-jre-alpine3.7

RUN apk update && \
    apk add ca-certificates wget && \
    update-ca-certificates

ENV JMETER_HOME=/usr/share/apache-jmeter \
    JMETER_VERSION=5.3 \
    TEST_SCRIPT_FILE=/var/jmeter/test.jmx \
    TEST_LOG_FILE=/var/jmeter/test.log \
    TEST_RESULTS_FILE=/var/jmeter/test-result.xml \
    PATH="~/.local/bin:$PATH" \
    PORT=443 
    
RUN wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar zxvf apache-jmeter-${JMETER_VERSION}.tgz  && \
    rm -f apache-jmeter-${JMETER_VERSION}.tgz && \ 
    mv apache-jmeter-${JMETER_VERSION} ${JMETER_HOME}

COPY test.jmx ${TEST_SCRIPT_FILE}

EXPOSE 443

CMD export PATH=~/.local/bin:$PATH && \
    $JMETER_HOME/bin/jmeter -n \
    -t=$TEST_SCRIPT_FILE \
    -j $TEST_LOG_FILE \
    -l=$TEST_RESULTS_FILE  && \
    echo -e "\n\n======TEST LOGS========\n\n"  && \
    cat  $TEST_LOG_FILE && \
    echo -e "\n\n======TEST RESULTS========\n\n"  && \
    cat $TEST_RESULTS_FILE
```

- Since I use AWS ECS, I also use the Docker repository ECR for convenience.
  ![ecr](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ecr.JPG)

### 3.4 Build ECS Cluster and Run Task

- Create an ECS Cluster
    - Use Fargate or EC2 as the base. Fargate means you only care about the network. With EC2, you also need to manage instances. Both have resource limits, and my account can handle up to 40 vCPUs. For more resources, clone the cluster across regions.
    - To configure different outbound IPs for accessing the target website, set up a more complex VPC network.
- Create Task Definitions
    - Create tasks to run the Jmeter containers pushed to ECR
    - Configure logs to CloudWatch for monitoring results.

![ecsTask](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ecs_task.JPG)

- Run the task
    - Configure scaling to maximize resource usage for the script.

![ecsRunTask](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ecs_run_task.JPG)

### 3.5 Check CloudWatch Logs

- Logs declared in the Dockerfile are pushed to CloudWatch.   
  ![Log](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/cloudwatch.JPG)

