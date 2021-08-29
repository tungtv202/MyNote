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

# Amazon `Elastic Container` Service

- quản lý các container, service của `docker`
- có thể hiểu là giống với `docker-swarm`

![Overview](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_overview.PNG)

- Khi tạo ECS sẽ có 2 lựa chọn: dùng Fargate hoặc EC2. Điểm khác biệt là Fargate không cung cấp Instance, còn EC2 thì
  ngược lại
    - Fargate
        - Price based on task size
        - Requires network mode awsvpc
        - AWS-managed infrastructure, no Amazon EC2 instances to manage
    - EC2
        - Price based on resource usage
        - Multiple network modes available
        - Self-managed infrastructure using Amazon EC2 instances

## 1. Task Definition

- Create
  https://ap-east-1.console.aws.amazon.com/ecs/home?region=ap-east-1#/taskDefinitions/create
    - Step 1: Select launch type compatibility
        - Chọn `EC2`
    - Step 2: Configure task and container definitions
        - Đặt tên tại `Task Definition Name*`
        - Các trường còn lại có thể để default
        - Tại mục `Container Definitions` click `Add container`
          ![AddContainer](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_AddContainer.PNG)
          - Lưu ý trường `Image*`: paste Image URI (lấy trong ECR). Ví
          dụ:  `168146697673.dkr.ecr.ap-east-1.amazonaws.com/tungexplorer:latest`    
          - Click `Add`
        - Click `Create`

## 2. Clusters

- Create
  https://ap-east-1.console.aws.amazon.com/ecs/home?region=ap-east-1#/clusters
    - Step 1: Select cluster template
        - Select `EC2 Linux + Networking`
    - Step 2: Configure cluster
      ![ECS_CreateClusterConfig](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_CreateClusterConfig.png)
    - Step 3: result
        - EC2 instance mới được tạo
        - Cluster được tạo
- Run new `Task`
    - Vào `cluster detail` vừa
      tạo: https://ap-east-1.console.aws.amazon.com/ecs/home?region=ap-east-1#/clusters/mycluster-demo/tasks
      ![ECS_ClusterDetail](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_ClusterDetail.JPG)
        - Swithch tab `Tasks`
        - Click `Run new Task`
    - Input form, and click `Run Task`
        - Lưu ý tại trường `Number of tasks`. Trường hợp có 2 EC2, nhưng nhập chỉ là `1` task, thì sẽ chỉ có 1 EC2 chạy
          docker được khai báo ở `Task definition`. Ngược lại, nếu nhập `2` thì `docker container` sẽ được run ở cả 2
          instance
    - Result
        - EC2 console
          ![ECS_RunTask_Console](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_RunTask_Console.JPG)
        - Web browser
          ![ECS_RunTask_WebBrowser](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_RunTask_WebBrowser.JPG)
    - Note
        - Trường hợp `stop docker` trong ec2, thì task ở `cluster` sẽ bị stop, giảm xuống tương ứng
- Run new `Services`
    - Lưu ý trường `Service type*` (chọn DAEMON)
      ![ECS_CreateNewService](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_CreateNewService.png)
    - Services sau khi tạo xong, thì `container` trong ec2 sẽ luôn luôn được chạy, nếu stop manual, thì sẽ tự động được
      restart lại

- Note
    - Có thể sẽ có sự conflict giữa việc tạo `Tasks` trên aws, với việc Task được sinh ra do tạo `Serrvices`

## 3. What is the difference between a task and a service in AWS ECS?

A `Task Definition` is a collection of 1 or more container configurations. Some Tasks may need only one container, while
other Tasks may need 2 or more potentially linked containers running concurrently. The Task definition allows you to
specify which Docker image to use, which ports to expose, how much CPU and memory to allot, how to collect logs, and
define environment variables.

A `Task` is created when you run a Task directly, which launches container(s) (defined in the task definition) until
they are stopped or exit on their own, at which point they are not replaced automatically. Running Tasks directly is
ideal for short running jobs, perhaps as an example things that were accomplished via CRON.

A `Service` is used to guarantee that you always have some number of Tasks running at all times. If a Task's container
exits due to error, or the underlying EC2 instance fails and is replaced, the ECS Service will replace the failed Task.
This is why we create Clusters so that the Service has plenty of resources in terms of CPU, Memory and Network ports to
use. To us it doesn't really matter which instance Tasks run on so long as they run. A Service configuration references
a Task definition. A Service is responsible for creating Tasks.

Services are typically used for long running applications like web servers. For example, if I deployed my website
powered by Node.JS in Oregon (us-west-2) I would want say at least three Tasks running across the three Availability
Zones (AZ) for the sake of High-Availability; if one fails I have another two and the failed one will be replaced (read
that as self-healing!). Creating a Service is the way to do this. If I had 6 EC2 instances in my cluster, 2 per AZ, the
Service will automatically balance Tasks across zones as best it can while also considering cpu, memory, and network
resources.

*UPDATE*:

```text
I'm not sure it helps to think of these things hierarchically.

Another very important point is that a Service can be configured to use a load balancer, so that as it creates the Tasks—that is it launches containers defined in the Task Defintion—the Service will automatically register the container's EC2 instance with the load balancer. Tasks cannot be configured to use a load balancer, only Services can.
```

![ClusterArchitect](https://i.stack.imgur.com/i91bc.png)
