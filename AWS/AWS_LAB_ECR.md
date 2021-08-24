---
title: AWS - LAB - ECR
date: 2020-01-25 18:00:26
updated: 2020-01-25 18:00:26
tags:
    - aws
    - ecr
category: 
    - aws
---

# Amazon `Elastic Container Registry`
- là dịch vụ lưu trữ, quản lý các `docker container images` trên AWS
- có thể hình dung nó giống như docker registry, nhưng chạy trên cloud

https://ap-east-1.console.aws.amazon.com/ecr/home?region=ap-east-1#

![ECR_create](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECR_create.PNG)

## 1. Demo
### 1.1 create docker images
- Dockerfile

```bash
FROM ubuntu:16.04

# Install dependencies
RUN apt-get update
RUN apt-get -y install apache2

# Install apache and write "Hello Tungexplorer" 
RUN echo "Hello Tungexplorer" > /var/www/html/index.html

# Configure apache
RUN echo '. /etc/apache2/envvars' > /root/run_apache.sh
RUN echo 'mkdir -p /var/run/apache2' >> /root/run_apache.sh
RUN echo 'mkdir -p /var/lock/apache2' >> /root/run_apache.sh
RUN echo '/usr/sbin/apache2 -D FOREGROUND' >> /root/run_apache.sh
RUN chmod 755 /root/run_apache.sh

EXPOSE 80
CMD /root/run_apache.sh
```
- build docker images from Dockerfile
```bash
docker build -t myapache .
```
- check image build done
```bash
docker images
```
- run container
```
 docker run -d -p 80:80 myapache
```
- Result:   

![Docker Build Done](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECR_build_docker_done.PNG)

### 1.2 Push docker images to ECR
- tạo EC2 role, và attact vào Instance, mục đích để khi chạy aws cli không phải configure   
```
    > IAM
        > Roles
            > Create Role
                > EC2
                    > Select "AmazonEC2ContainerRegistryFullAccess" 
```
https://console.aws.amazon.com/iam/home?region=ap-east-1#/roles/full_ECR
![ECS_CreateRole](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_CreateRole.PNG)

- attact Role vừa tạo vào EC2   

![ECS_Attact_Role](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_Attact_Role.PNG)
- login
```
aws ecr get-login --no-include-email --region ap-east-1
```
sau khi run command trên, kết quả trả về format như sau:
```
docker login -u AWS -p eyJwYXlsb2FkIjoicndSNGY4bUJTY2xXZUdReHo5NWN0K3RTMzdGUkdIdEsyZnFsRys1a2RaMlFDL0JyNk5JNHpMLzNbTBUSXJuQUFhdUdlQT09IiwidmVyc2lvbiI6IjIiLCJ0eXBlIjoiREFUQV9LRVkiLCJleHBpcmF0aW9uIjoxNTc5OTc2MjEzfQ== https://168146697673.dkr.ecr.ap-east-1.amazonaws.com
```
thực hiện run command trả về, để login vào ecr (login vào thì mới push images được)
- docker tag
```
docker tag myapache:latest 168146697673.dkr.ecr.ap-east-1.amazonaws.com/tungexplorer:latest
```
- docker push lên ECR
```
docker push 168146697673.dkr.ecr.ap-east-1.amazonaws.com/tungexplorer
```
```bash
# result exp
ubuntu@ip-172-31-21-90:~$ docker push 168146697673.dkr.ecr.ap-east-1.amazonaws.com/tungexplorer
The push refers to repository [168146697673.dkr.ecr.ap-east-1.amazonaws.com/tungexplorer]
6b7f18c2e1d7: Pushed 
93ebf59e7508: Pushed 
53bb19ca1654: Pushed 
fb9d3d6977d1: Pushed 
bfaa8df62234: Pushed 
fd6a28796899: Pushed 
5933364a1fec: Pushed 
164f642a3cbc: Pushed 
fa1693d66d0b: Pushed 
293b479c17a5: Pushed 
bd95983a8d99: Pushed 
96eda0f553ba: Pushed 
latest: digest: sha256:90780667e1c4f42a8818d6b30260bf98078e6f7d693fd8245b2be4cab83bc216 size: 2816
ubuntu@ip-172-31-21-90:~$ 
```
![ECS_UplaodImagesDone](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/ecs/ECS_uploadImagesDone.PNG)