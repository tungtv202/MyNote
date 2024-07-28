---
title: AWS - LAB - ECS
date: 2020-01-25 18:00:26
updated: 2020-01-25 18:00:26
tags:
    - aws
    - ecs
category: 
    - aws
---

# Amazon Elastic Container Service (ECS)

- ECS manages Docker containers and services.
- ECS is similar to Docker Swarm.

- When creating ECS, you have two options: Fargate or EC2. The main difference is that Fargate does not provide instances, while EC2 does.

    - **Fargate**:
        - Price based on task size.
        - Requires network mode awsvpc.
        - AWS-managed infrastructure, no Amazon EC2 instances to manage.

    - **EC2**:
        - Price based on resource usage.
        - Multiple network modes available.
        - Self-managed infrastructure using Amazon EC2 instances.

## What is the difference between a task and a service in AWS ECS?

- **Task Definition**: A collection of one or more container configurations. Some tasks may need only one container, while other tasks may need two or more potentially linked containers running concurrently. The task definition allows you to specify which Docker image to use, which ports to expose, how much CPU and memory to allot, how to collect logs, and define environment variables.

- **Task**: Created when you run a task directly, which launches containers (defined in the task definition) until they are stopped or exit on their own, at which point they are not replaced automatically. Running tasks directly is ideal for short-running jobs, such as those performed via CRON.

- **Service**: Used to ensure that you always have a certain number of tasks running at all times. If a task's container exits due to an error, or the underlying EC2 instance fails and is replaced, the ECS Service will replace the failed task. This is why we create clusters so that the service has plenty of resources in terms of CPU, memory, and network ports to use. It doesn't really matter which instance tasks run on as long as they run. A service configuration references a task definition. A service is responsible for creating tasks.

Services are typically used for long-running applications like web servers. For example, if I deployed my website powered by Node.JS in Oregon (us-west-2), I would want at least three tasks running across the three Availability Zones (AZ) for the sake of high availability; if one fails, I have another two, and the failed one will be replaced (self-healing). Creating a service is the way to do this. If I had six EC2 instances in my cluster, two per AZ, the service will automatically balance tasks across zones as best it can while also considering CPU, memory, and network resources.

*UPDATE*:

```text
I'm not sure it helps to think of these things hierarchically.

Another very important point is that a service can be configured to use a load balancer, so that as it creates the tasks—that is, it launches containers defined in the task definition—the service will automatically register the container's EC2 instance with the load balancer. Tasks cannot be configured to use a load balancer, only services can.
```
