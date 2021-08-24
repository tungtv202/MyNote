---
title: AWS - LAB- Beanstalk
date: 2020-01-27 18:00:26
updated: 2020-01-27 18:00:26
tags:
    - archived
category: 
    - z.archived
---

# Elastic Beanstalk - một service để deploy web trên AWS  
Tìm hiểu Elastic Beanstalk bằng cách demo deploy webapp.

## 1. Kịch bản
Sử dụng file demo.war, là 1 file được build từ code của java web dùng để deploy.
## 2. Prepare
- Tài khoản AWS. Tài khoản mới sẽ được free 1 số gói tier 1 năm.  
- Chọn Region. Mục đích để chọn vị trí địa lý web server muốn triển khai.   
![Chọn Region](https://viblo.asia/uploads/78e2dc43-6017-4cde-8e91-194c0575f7c1.png)

## 3. Step by step
### Step 1. Vào service EB
https://us-west-2.console.aws.amazon.com/elasticbeanstalk
![EB](https://viblo.asia/uploads/38ea1ece-a1bd-44fe-abd0-f8c24943c777.png)

### Step 2. Thực hiện cấu hình trước khi Create Application.
![Config](https://viblo.asia/uploads/0220bf04-6929-4c16-8d43-a6e3e1863f98.png)  

Cấu hình database nếu web app muốn sử dụng gói database tích hợp luôn của Amazon        
Thực hiện Create Application và chờ vài phút dể Beanstalk triển khai.   

![Wait for done](https://viblo.asia/uploads/f191c349-1303-4673-b2be-64d2766e2938.png)!  
Website sau khi triển khai thành công có thể vào bằng IP hoặc domain. (xem log, hoặc detail web app để biết thông tin).   

## 4. Tản mạn   
AWS cung cấp rất nhiều module, để tùy chỉnh cloud. Ví dụ như Firewall, Group Security… Ngoài monitor web app trong Beanstalk, có thể monitor web server trong EC2 (Elastic Compute Cloud). Sử dụng Bill Dashboard để xem số tiền phải trả cho các dịch vụ đã sử dụng.   
![Dashboard](https://viblo.asia/uploads/7d92d4cb-1e57-405b-b808-30662b8fe7f2.png)