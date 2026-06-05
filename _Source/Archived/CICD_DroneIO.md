---
title: CICD - DroneIO
date: 2019-05-17 18:00:26
updated: 2019-05-17 18:00:26
tags:
    - archived
categories:
    - z.archived
---

# Drone IO - tool hỗ trợ việc CICD

## 1. CICD là gì?

CI CD nó là một tập hợp các bộ công cụ, có chức năng khác nhau, nhưng được kết hợp khéo léo tùy theo ý người quản trị,
để xây dựng lên một hệ thống phát triển phần mềm, tự động test, tự động deploy, tự động report... mọi thứ tuần tự với
nhau, tạo lên 1 quy trình tự động". Giả sử có tình huống lý tưởng như sau: dev đẩy pull từ local lên github, và có 1
tools nào đó tự động phát hiện ra rằng github đang có event mới...cái tool này phân loại ra được đâu là pull request,
change, commit...Và tùy theo mỗi case, nó sẽ xử lý hành động tiếp theo. Ví dụ như có commit mới, Web server tự động kéo
code mới về, tự động test unit các kiểu, nếu sucess thì deploy, deploy xong thì gửi mail report về cho ai đó.   
Vậy là gồm 3 bên:

- Github
- Web server
- Drone.io (là một trong những “tool” làm được điều đó)

## 2. Drone dựa trên nền tảng Docker, vậy Docker là gì?

Thực sự thì nếu giải thích docker theo kiểu khái niệm như wikipedia thì chắc rất khó hiểu. Giải thích theo kiểu những gì
nó làm được có khi dễ hiểu hơn. Ví dụ như bây giờ 1 team, bắt đầu start 1 dự án, ông nào cũng phải cài môi trường, rồi
database, rồi IDE, cấu hình web..vv. Kiểu kiểu mọi người phải đồng bộ với nhau ấy, rất chi là mất công. Nếu mà sử dụng
docker, thì 1 ông cài thật chuẩn, xong rồi đóng gói lại thành 1 docker, rồi các người khác chỉ việc kéo về, và "Run" cái
docker đó thôi. Nghe có vẻ giống kiểu máy ảo nhỉ? cài lên, xong đóng gói lại thành file .iso , đem sang máy khác burn,
được cái máy ảo tương tự. Thực ra thì nó có khác nhau ở cái tầng kernel bên dưới.

```
Note: docker làm được nhiều điều hơn nữa, nhưng mà mình chỉ thấy được lợi ích của nó khi cài Drone là như vậy thôi.
```

## 3. Cài đặt Drone IO

### Step 1. Tạo server

Reg tạm cái acc Digital Ocean, create 2 con server:
![Server Digital Ocean](https://viblo.asia/uploads/ec4b6a6d-cbb6-4b5e-ad94-e1901acc7893.jpg)        
Con drone-server sẽ dùng để cài drone, còn web-server để deploy java web code.

### Step 2.

Cài docker, docker compose trên drone-server.       
Cài docker Cái này trang chủ của nó hướng dẫn dài lê thê
đây: https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-using-the-convenience-script Cơ mà
Server mình là ubuntu 16.04, nên cài vắn tắt sau là đủ:

```bash
sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce
```

Gõ lệnh “docker images” để test xem cài xong chưa       
![Docker Compose](https://viblo.asia/uploads/2c0dc258-2d98-4a63-aa29-82173013df72.png)

Cài docker compose Lựa mãi mới được cái link cài thành công:
https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04

 ```shell
 sudo curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)"  

 sudo chmod +x /usr/local/bin/docker-compose
 ```

Test done!

 ```
 docker-compose –v
 ```

### Step 3. Cài drone bằng docker

Kéo cái gói docker cài sẵn drone chính chủ về

```bash
docker pull drone/drone:0.7
```

Tạo một cái file docker-compose.yml (tạo luôn tại thư mục gốc trên server luôn cho nóng, đỡ phải mkdir directory phiền
hà) Format file docker-compose.yml như sau:

```yml
version: '2'

services:
  drone-server:
    image: drone/drone:0.7
    ports:
      - 80:8000
    volumes:
      - /var/lib/drone:/var/lib/drone/
    restart: always
    environment:
      - DRONE_OPEN=true
      - DRONE_HOST=${DRONE_HOST}
      - DRONE_GITHUB=true
      - DRONE_GITHUB_CLIENT=${DRONE_GITHUB_CLIENT}
      - DRONE_GITHUB_SECRET=${DRONE_GITHUB_SECRET}
      - DRONE_SECRET=${DRONE_SECRET}

  drone-agent:
    image: drone/drone:0.7
    command: agent
    restart: always
    depends_on:
      - drone-server
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DRONE_SERVER=ws://drone-server:8000/ws/broker
      - DRONE_SECRET=${DRONE_SECRET}
```

Thay ${DRONE_HOST} thành địa chỉ con drone-server : 128.199.107.170 Vào github tạo 2 giá trị ${DRONE_GITHUB_CLIENT} với
${DRONE_GITHUB_SECRET}

![DroneConfig](https://viblo.asia/uploads/04a17019-039c-4a12-a41e-bdb5dc9a44a4.png)

${DRONE_SECRET} ? What is it? Chắc là password cho mình tự nhập 😃), mình đặt luôn là “dronesecret” cho nó chuyên
nghiệp. À, Mình đã “vô tình” thay cái “ws://drone-server:8000/ws/broker” thành ws:// 128.199.107.170:8000/ws/broker Kết
quả là nó lỗi, không chạy được. Tổng kết lại:

```yml
version: '2'

services:
  drone-server:
    image: drone/drone:0.7
    ports:
      - 80:8000
    volumes:
      - /var/lib/drone:/var/lib/drone/
    restart: always
    environment:
      - DRONE_OPEN=true
      - DRONE_HOST=128.199.107.170
      - DRONE_GITHUB=true
      - DRONE_GITHUB_CLIENT=291495405448f01f3c90
      - DRONE_GITHUB_SECRET=4241178f98c68c7ebde15b9b3266f57a12343924
      - DRONE_SECRET=dronesecret

  drone-agent:
    image: drone/drone:0.7
    command: agent
    restart: always
    depends_on:
      - drone-server
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DRONE_SERVER=ws://drone-server:8000/ws/broker
      - DRONE_SECRET=dronesecret
```

Chạy docker bằng lệnh:

```bash
root@drone-server:~# docker-compose up
```

![Log](https://viblo.asia/uploads/9fc34fe4-5e05-4c7c-9751-3c5b4dd2a6d8.png)

Test truy cập vào website http://128.199.107.170/
![droneweb](https://viblo.asia/uploads/74f95324-280f-4b5a-b4c4-43a2c0e6cff4.png)

Click vào login, và thực hiện đăng nhập bằng tài khoản github.com Vào Accounts và lựa chọn lấy 1 repository trên
github.com

![drone-github](https://viblo.asia/uploads/66adaeb0-6c3f-4368-8560-67f989b811e5.png)

My repository: https://github.com/tungtv202/SpringWebDemo Ở đây có sẵn cái project mẫu, viết bằng java, có dùng
SpringFramework. Cái repository này, quan trọng nhất là cái file .drone.yml Bởi khi github có sự kiện mới, thì thằng
drone sẽ đọc cái file .drone.yml này mà triển. Nôm na cái file này thì ghi tuần tự các bước phải làm. Nội dung cái file
.drone.yml ghi gì, thì từ từ viết. Lên ý tưởng đã.

## 4. Thử nghiệm auto Deploy với Drone

### Step 4. Kịch bản

“Trên github có sẵn code java rồi, bây giờ ta sẽ pull cái code này về con web-server, sau đó deploy nó bằng maven, rồi
quăng file .war vào thư mục của tomcat. Sau đó ta sẽ bật tomcat lên, truy cập vào cái website Springwebdemo đó. Để kiểm
tra mọi thứ đúng quy trình. Sau đấy ta sẽ edit giao diện code của Project SpringWebdemo, rồi commit lên github.com, xem
cái thằng drone nó có tự động deploy không? Nếu giao diện website có thay đổi, vậy là thành công =)), Ý, nhưng mà vậy
thì đơn giản quá, làm cho nó complex lên tý =)) ta sẽ sử dụng cái plugin maven-checkstyle-plugin, được khai báo trong
file pom.xml, cái plugin này sẽ check các error liên quan tới style code của project, nếu mà error >1, thì sẽ không
deploy, nếu error=0 thì sẽ deploy, deploy xong sẽ gửi email về gmail cho mình ” => Kịch bản tuyệt vời

### Step 5. Cài đặt tomcat, java, maven

https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-8-on-ubuntu-16-04

### Step 6: Cài ssh github cho web-server, deploy Springwebdemo trên web-server

Mục đích để sau này viết command trong file .drone.yml dễ hơn, không phải nhập username, password Test thử cái web
http://128.199.72.109:8080/springwebdemo/
![Spring web demo](https://viblo.asia/uploads/f4bf5c35-2509-4b7d-ae76-59f92191d386.png)

### Step 7. Biên soạn cái file .drome.yml

Làm từng bước vậy viết cái đoạn auto deploy đã, thành công rồi sẽ edit lại để nó chuyển sang kiểu check error style, với
report qua email sau.

```yml
pipeline:
  ssh:
    image: appleboy/drone-ssh
    host: 128.199.72.109
    username: root
    password: framgia
    port: 22
    script:
      - cd /root/workspace/SpringWebDemo/
      - git pull origin master
      - mvn install
      - rm -rf /opt/tomcat/webapps/springwebdemo*
      - mv /root/workspace/SpringWebDemo/target/springwebdemo.war /opt/tomcat/webapps/
```

Làm sao để mình biết được cách viết file drone.yml này? Mình vào http://plugins.drone.io/ , ở đây support nhiều plugin,
ssh, email, git, S3…Vào đọc document, rồi bắt chiếc thôi

### Step 8. New commit to github

Thực hiện edit file /src/main/webapp/WEB-INF/views/index.jsp trên local, và commit nó lên github.com. Theo dõi xem điều
gì xảy ra Đầu tiên là website project. View đã auto thay đổi

![Auto deploy 1](https://viblo.asia/uploads/96b97948-9bb9-4367-8adb-9d5beaec19de.png)       
Giao diện drone cũng thế, click vào clone và ssh, hiện console log luôn:
![Droneio log](https://viblo.asia/uploads/77026956-3c01-4ebb-b14e-8355781bc570.png)