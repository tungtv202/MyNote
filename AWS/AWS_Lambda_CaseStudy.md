---
title: AWS - Lambda - Case study
date: 2018-10-14 18:00:26
tags:
    - aws
    - lambda
category: 
    - aws
---

# Các case study nổi tiếng về Lambda
### 2.1 Cocacola với bài toán máy bán hàng tự động
- a. Bài toán   
Công ty Cocacola sử dụng máy bán hàng tự động, và khách hàng có thể thanh toán bằng các loại card.
Trước khi biết đến serverless, Cocacola sử dụng dịch vụ AWS EC2, gồm 6 máy chủ t2 medium. 
Và chi phí hàng năm mất tầm $13000. 
Sau khi chuyển đổi sang sử dụng Lambda thì chi phí hàng năm giảm xuống chỉ còn ~$4500
- b. Phân tích
![Cocacola](https://dashbird.io/images/blog/2018-07-04/coca-cola-serverless-setup.jpg)
Với mô hình này, rất dễ thấy trong các app trên server.
Mấu chốt chỉ là, các nhà quản trị sẽ không cần phải quan tâm tới các bài toán tài nguyên server, 
và làm sao tiết kiệm được chi phí khi không sử dụng.
Chỉ khi nào có khách hàng thực hiện mua bán tại máy bán hàng tự động, thì lúc này Cocacola mới mất tiền cho Amazon.
Trường hợp máy bàn hàng hỏng, hay không có khách, thì sẽ không phải tốn chi phí gì cả.
Thay vì sử dụng EC2 như cũ, thì chi phí tiền bỏ ra gần như là cố định, và khi trường hợp số EC2 được scale lên thì chi phí sẽ tăng lên.

### 2.2 Benchling với bài toán phục vụ các nhà khoa học
- a. Bài toán   
Benchling là 1 công ty ở San Francisco, đây là công ty cung cấp phần mềm giải pháp cho việc nghiên cứu và phát triển.
Các nhà khoa học (khách hàng của Benchling), sử dụng dịch vụ của công ty. 
Trong đó có 1 dịch vụ CRISPR Analysis. Các nhà khoa học nhập vào một mẫu gen, sau đó hệ thống của Benchling sẽ tính toán và xử lý gì đó để trả về kết quả.
Vấn đề Benchling gặp phải là với kiến trúc hiện tại gồm các Disk để lưu trữ các mẫu gen, phụ vụ cho tìm kiếm, và 1 số lượng các server đảm nhiệm việc tính toán và trả về kết quả.
Thì toàn bộ thời gian mà các nhà khoa học đợi chờ là 30s. 
Thực tế function tìm kiếm và tính toán này cũng không được các nhà khoa học sử dụng thường xuyên.
Yêu cầu đặt ra là giảm thời gian tìm kiếm và tính toán xuống vài giây. 
Bài toán cost được đặt ra. Và Benchling đã tìm đến AWS 
![Benchling](https://d1.awsstatic.com/case-studies/Benchling_architecture.945030da5d79e92d3d4da65a9c3ffb5af4fdbc79.jpg)

- b. Phân tích  
Lambda được Benchling sử dụng, và chỉ là 1 phần trong toàn bộ hệ thống của công ty.
Thay vì lưu mẫu gen trong Disk như trước, thì giờ Benchling lưu trữ trên S3.
Code tính toán thuật toán, được sử dụng ở Lambda.
Với việc tận dụng tài nguyên Infra của Amazon, và lợi ích, chỉ phải trả tiền khi có request. Đã giúp cho Benchling vừa tiết kiệm được chi phí, vừa giải quyết được bài toán performance.
Không phải tốn tiền maintaince server như trước.
### 2.3 iRobot và bài toán scale
- a. Bài toán   
iRobot là một công ty cung cấp các robot vệ sinh nhà cửa. Đã được thành lập từ lâu, và rất phát triển.
Thủa sơ khai thì công ty chỉ cung cấp các robot tự động, và không có sự kết nối với internet.
Khi Công ty bắt đầu ra mắt mẫu robot Roomba. Có chức năng kết nối Internet (IoT).
Số lượng khách hàng sử dụng thử nghiệm Roomba tăng lên rất lớn. 
Mẫu robot Roomba có nguy cơ sẽ bị mất điểm, vì hệ thống server tính toán không kịp.
![iRobot](https://d1.awsstatic.com/case-studies/US/Robot%20registration.b172a8d0a29446cd78ed7bab60c79534b4bb53c4.PNG)
- b. Phân tích  
Tương tự như với các case study khác, iRobot đã thành công khi sử dụng Lambda, 
vì gần như không phải quan tâm gì tới bài toán scale. 
Với nền tảng Infra của Amazon, mọi chuyện đã được giải quyết


