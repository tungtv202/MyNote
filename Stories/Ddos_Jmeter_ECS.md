---
title: DDos, Stress test, distribution test với Jmeter, Docker, AWS ECS
date: 2020-11-08 18:00:26
tags:
    - jmeter
    - aws
    - ecs
    - test
category: 
    - stories
---

# Ddos, Stress Test, Distributional Test với combo Jmeter, Docker, AWS ECS 
## 1. Lời nói đầu
Bài viết này mình note lại các bước mình trải nghiệm với combo 3 thằng trên để stress test hệ thống web app của mình. Mục đích ban đầu là mình muốn performance test, stress test dưới hướng tiếp cận của end user (bên ngoài đi vào).  
Nói "DDos, Distributional" thì không tới, bởi resource infra của mình không đủ, nhưng architect thì đúng là hướng tới điều này.     
Hi vọng với những ghi chép lại về trải nghiệm của mình, một ngày nào đó sẽ giúp bạn rút ngắn thời gian hơn trong việc sơ khai đi tìm giải pháp cho bài toán cần stress test, performance test...

Một số kiến thức cần biết sơ sơ nếu bạn có ý định làm theo bài viết:
- Jmeter một chút
- Docker một chút
- AWS ECS một chút

## 2. Kịch bản nhanh
- Jmeter: giải thích nhanh gọn thì nó là 1 tool có hỗ trợ việc stress test. Mình có thể viết kịch bản là truy cập vào 1 website (hoặc 1 api) và thực hiện các hành động nào đấy (GET, POST...). Nó có hỗ trợ về cpu, thread, số loop thực hiện lặp lại, có export file kết quả test. Và đặc biệt nó hỗ trợ export ra file test plan `.jmx`. Thích hợp để chạy nó trên các server. 
- Docker: mình sử dụng file `.jmx` của Jmeter để build ra container. 
- AWS ECS: một service của aws, để chạy các container. Đây sẽ là nơi cung cấp các resource infra để thực hiện chạy script (cpu, ram, network...). Dùng ECS để dễ scale thoải mái theo ý mình, không phải quản lý từng node server. Khi nào test mình mới run task, lúc đó sẽ không tốn quá nhiều tiền. Có thể khai thác tối đa ECS bằng cách tạo nhiều cluster trên nhiều region.
Ngoài ECS ra, có thể dùng bất cứ thằng nào khác như K8s, Docker swarm cũng tương tự. 

![Overview](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ddos_overview.jpg)

## 3. Step by step
## 3.1 Viết file kịch bản Jmeter
- Tải Jmeter https://jmeter.apache.org/download_jmeter.cgi 
    - Cần cài java trước (tối thiểu java 8)
    - Có cung cấp giao diện UI. Chỉ cần tải file về, giải nén và vào thư mục /bin để chạy file .jar là được.
    - Lưu ý khi cài đặt trên linux, cần để ý version. (mình cài trên ubuntu, thì mặc định là version 2.x, khá cũ. Chạy file script mình tạo trên window bị lỗi, vì outdated version)
- Viết script (mình không viết chi tiết các bước mình sử dụng tool Jmeter như thế nào)
    - Jmeter có chễ độ record
    - Kịch bản: sử dụng https://webhook.site/ làm website victim để test. Khi bạn truy cập vào website này, site sẽ sinh ra 1 unique url, bất kỳ request nào tới url này, thì sẽ được visualize trực tiếp trên website webhook.site của trình duyệt của bạn. 
    - File `jmx` mình viết để truy cập vào webhook.site và POST message đơn giản: https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/test.jmx 
    - Mình đã thử viết file script file tạo đơn hàng trên 1 website bán hàng (không yêu cầu captcha) thấy vẫn oke. => tức là Jmeter viết được tuốt

![jmetertool](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/jmeter_tool.JPG)

## 3.2 Test file script `.jmx`
- Chạy file script thông qua tool có UI dưới PC đơn giản hơn. Sau khi thực thi, kiểm tra trên webhook.site thấy có message gửi đến là thành công. 
![webHook.site](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/webhook.site.JPG)
- Chạy trên server linux dùng cli 
```bash
bash ~/jmeter/apache-jmeter-5.3/bin/jmeter.sh -n -t ~/jmeter/01/test.jmx -j tmp1.log -l tmp2.xml
```
    - Trong đó file test.jmx là file plan test
    - tmp1.log là file log
    - tmp2.xml là file result của jmeter (call http request 200, 404, 403 sẽ show hết ở đây)
    - Lưu ý khi chạy trên server cần thêm parameter `-n` là chạy với mode NONE GUI
## 3.3 Dockerfile
- Sau khi test cli thấy mọi thứ oke, mình thực hiện build Dockerfile    

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

- Vì mình sử dụng AWS ECS, nên sử dụng luôn docker repository ECR luôn cho tiện. 
![ecr](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ecr.JPG)


### 3.4 Build ECS Cluster và Run Task
- Tạo ECS Cluster
    - Dùng base Fargate hoặc EC2 tùy bạn. Dùng Fargate thì cluster bạn chỉ care về network. Dùng EC2 thì phải care thêm Instance nữa. Mình đã thử thì cả 2 thằng đều bị limit resource infra. Theo tính toán thì tài khoản của mình chỉ maximum được tầm 40 vCPU. Nếu muốn resource nhiều hơn nữa có thể tạm dùng cách là clone Cluster ra các region khác. 
    - Nếu cần cấu hình IP outbound ra ngoài khác nhau (có nhiều IPV4 khi truy cập vào website victim), cần cấu hình network vpc phức tạp hơn. 
- Tạo Task definitions 
    - Tạo task chạy các jmeter container mà mình đã push lên ecr 
    - Lưu ý bước này: cần cấu hình log để về CloudWatch để tiện theo dõi kết quả của các container. 

![ecsTask](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ecs_task.JPG)

- Run task
    - Bước này lưu ý cấu hình scale sao cho hợp lý, để khai thác tối đa được resource infra tham gia chạy script. 

![ecsRunTask](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/ecs_run_task.JPG)

### 3.5 Check log CloudWatch
- Log của jmeter mà mình khai báo ở Dockerfile sẽ được đẩy về cloudwatch.   
![Log](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/jmeter/cloudwatch.JPG)

Thank for reading...

