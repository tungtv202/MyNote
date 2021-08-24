---
title: AWS - SQS
date: 2018-09-11 18:00:26
updated: 2018-09-11 18:00:26
tags:
    - archived
category: 
    - z.archived
---

# Amazon Simple Queue Service (SQS)
 là 1 dịch vụ hàng đợi message queue, giống như message queue của Redis hay ActiveMQ

## 1. Một vài điểm đặc biệt cần lưu ý của SQS
-	Mặc định các queue message trong SQS không đảm bảo được sắp xếp theo đúng trật tự mà chúng được thêm vào. Nếu muốn các message queue có trật tự thì cần phải thêm dữ liệu tuần tự vào message.
-	Vì SQS được lưu trữ trên nhiều máy chủ phân tán khác nhau, nên có thể sẽ tồn tại case là nhận SQS bị duplicate.
- Khi 1 component A lấy thông điệp B từ hàng đợi, thì thông điệp B đó vẫn nằm ở hàng đợi, nhưng sẽ không được trả về cho component nào khác. Tham số để setup thời gian pending này là Visibility Timeout. Sau khi component A xử lý xong, báo lại cho SQS Server, thì thông điệp B sẽ bị xóa khỏi hàng đợi. 
Lý do: vì SQS server không thể chắc chắn được component A đã lấy được thông điệp chưa.
- Dung lượng tối đa của một thông điệp là 256 KB.
- SQS phù hợp với logic có nhiều component xử lý các message queue khác nhau.

## 2. Các tham số quan trọng của message queue SQS
- Queue URL: bắt buộc cho mỗi request gửi lên, mục đích để định danh region, account AWS khi sử dụng dịch vụ SQS
Format
```
https://{REGION_ENDPOINT}/queue.|api-domain|/{YOUR_ACCOUNT_NUMBER}/{YOUR_QUEUE_NAME}
```
- Message ID : tối đa 100 ký tự, mục đích để định danh message Queue
-	Receipt Handle: mỗi lần thao tác với message Queue SQS, sẽ cần giá trị này. Nó như 1 token chỉ sử dụng được 1 lần, và sẽ bị thay đổi cho lần gửi tiếp theo. 
Format
```
MbZj6wDWli+JvwwJaBV+3dcjk2YW2vA3+STFFljTM8tJJg6HRG6PYSasuWXPJB+Cw
Lj1FjgXUv1uSj1gUPAWV66FU/WeR4mq2OKpEGYWbnLmpRCJVAyeMjeU5ZBdtcQ+QE
auMZc8ZRv37sIW2iJKq3M9MFx1YvV11A2x/KSbkJ0=
```
- MD5OfBody: Mã MD5 của chuỗi thông điệp không bị mã hóa.
- Body: payload của thông điệp.

## 3. Quick start trong Java
### a. Tạo queue
```java
AmazonSQS sqs = AmazonSQSClientBuilder.defaultClient();
CreateQueueRequest create_request = new CreateQueueRequest(QUEUE_NAME)
        .addAttributesEntry("DelaySeconds", "60")
        .addAttributesEntry("MessageRetentionPeriod", "86400");

try {
    sqs.createQueue(create_request);
} catch (AmazonSQSException e) {
    if (!e.getErrorCode().equals("QueueAlreadyExists")) {
        throw e;
    }
}
```

### b. Lấy danh sách queue
```java
AmazonSQS sqs = AmazonSQSClientBuilder.defaultClient();
ListQueuesResult lq_result = sqs.listQueues();
System.out.println("Your SQS Queue URLs:");
for (String url : lq_result.getQueueUrls()) {
    System.out.println(url);
}
```

### c. Lấy queue URL
```java
AmazonSQS sqs = AmazonSQSClientBuilder.defaultClient();
String queue_url = sqs.getQueueUrl(QUEUE_NAME).getQueueUrl();
```

### d. Xóa đi 1 queue
```java
AmazonSQS sqs = AmazonSQSClientBuilder.defaultClient();
sqs.deleteQueue(queue_url);
```
