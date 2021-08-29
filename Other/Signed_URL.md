---
title: Signed URL
date: 2019-05-12 18:00:26
updated: 2019-05-12 18:00:26
tags:
    - signed url
    - object storage
    - s3
category: 
    - other
---

# Signed URL

### 1. Khái niệm

Là việc sử dụng URL đã được "signed" để được cấp quyền truy cập vào "resource" mà developer cấu hình trước và được giới
hạn trong 1 khoản thời gian nhất định.  
Ví dụ:

- Đây là URL tới 1 resource file ảnh được lấy trên facebook

```
https://scontent.fhan2-1.fna.fbcdn.net/v/t1.0-9/59423202_442314843263996_7671343376326721536_n.jpg
```

File ảnh này hiện tại được set private quyền, không thể xem được.   
Và đây là Signed URL của file ảnh này:

```
https://scontent.fhan2-1.fna.fbcdn.net/v/t1.0-9/59423202_442314843263996_7671343376326721536_n.jpg?_nc_cat=101&_nc_oc=AQlnMDOmZYDHdq_ixK4jZzBLHzMdzb2AyEtZZQ4a4C-2E2YnH4LRaExofT0E86Xs-V1oNWDNO7tJ-3hvh-Y9JxX9&_nc_ht=scontent.fhan2-1.fna&oh=549bf01567ce4b588c9853b8b8783676&oe=5D60E9C4
```

Với Signed URL ta có thể "access" được vào "resource" file ảnh trên. (xem được).

Thường thì Signed URL hay đi kèm với các hệ thống lưu trữ dữ liệu Cloud Storage. Các service lớn đều cung cấp sẵn tính
năng này, như AWS S3, Google Cloud Storage, IBM Bluemix, Azure Blob Storage...

- Format Signed URL của AWS S3:

```
https://pres-url-test.s3-eu-west-1.amazonaws.com/test.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAJQ6UAEQOACU54C3A%2F20180927%2Feu-west-1%2Fs3%2Faws4_request&X-Amz-Date=20180927T100139Z&X-Amz-Expires=900&X-Amz-Signature=f6fa35129753e7626c850a531379436a555447bfbd597c19e3177ae3d2c48387&X-Amz-SignedHeaders=host
```

- Format Signed URL của Google Cloud Storage

```
https://storage.googleapis.com/example-bucket/cat.jpeg?X-Goog-Algorithm= GOOG4-RSA-SHA256&X-Goog-Credential=example%40example-project.iam.gserviceaccount .com%2F20181026%2Fus-central-1%2Fstorage%2Fgoog4_request&X-Goog-Date=20181026T18 1309Z&X-Goog-Expires=900&X-Goog-SignedHeaders=host&X-Goog-Signature=247a2aa45f16 9edf4d187d54e7cc46e4731b1e6273242c4f4c39a1d2507a0e58706e25e3a85a7dbb891d62afa849 6def8e260c1db863d9ace85ff0a184b894b117fe46d1225c82f2aa19efd52cf21d3e2022b3b868dc c1aca2741951ed5bf3bb25a34f5e9316a2841e8ff4c530b22ceaa1c5ce09c7cbb5732631510c2058 0e61723f5594de3aea497f195456a2ff2bdd0d13bad47289d8611b6f9cfeef0c46c91a455b94e90a 66924f722292d21e24d31dcfb38ce0c0f353ffa5a9756fc2a9f2b40bc2113206a81e324fc4fd6823 a29163fa845c8ae7eca1fcf6e5bb48b3200983c56c5ca81fffb151cca7402beddfc4a76b13344703 2ea7abedc098d2eb14a7
```

Bản chất Signed URL thực tế chỉ là việc truyền thêm các param vào URL, và các param này sẽ được Server xử lý để
verified.

### 2. Đặc điểm

- Signed URL là 1 tư tưởng kĩ thuật, và chỉ khi nó đi kèm với 1 service thì mới thành 1 danh từ riêng. Tức là Signed URL
  chỉ chung chung việc 1 URL đã được ký. Còn việc nó được ký như thế nào, sử dụng thuật toán nào để ký, hệ thống xác
  thực nó bằng cách nào. Thì việc này hoàn toàn tự quyết định bởi hệ thống cung cấp nó, mà không có 1 chuẩn chung nào
  cả.
- Signed URL không có tính định danh người truy cập. Bất cứ ai có được URL này đều có thể truy cập vào resource được với
  quyền tương đương nhau.

Format của Signed URL trong Google Cloud Storage:

```
https://storage.googleapis.com/example-bucket/cat.jpeg?X-Goog-Algorithm=
GOOG4-RSA-SHA256&X-Goog-Credential=example%40example-project.iam.gserviceaccount
.com%2F20181026%2Fus-central-1%2Fstorage%2Fgoog4_request&X-Goog-Date=20181026T18
1309Z&X-Goog-Expires=900&X-Goog-SignedHeaders=host&X-Goog-Signature=247a2aa45f16
9edf4d187d54e7cc46e4731b1e6273242c4f4c39a1d2507a0e58706e25e3a85a7dbb891d62afa849
6def8e260c1db863d9ace85ff0a184b894b117fe46d1225c82f2aa19efd52cf21d3e2022b3b868dc
c1aca2741951ed5bf3bb25a34f5e9316a2841e8ff4c530b22ceaa1c5ce09c7cbb5732631510c2058
0e61723f5594de3aea497f195456a2ff2bdd0d13bad47289d8611b6f9cfeef0c46c91a455b94e90a
66924f722292d21e24d31dcfb38ce0c0f353ffa5a9756fc2a9f2b40bc2113206a81e324fc4fd6823
a29163fa845c8ae7eca1fcf6e5bb48b3200983c56c5ca81fffb151cca7402beddfc4a76b13344703
2ea7abedc098d2eb14a7
```

Có thể sử dụng công cụ https://www.freeformatter.com/url-parser-query-string-splitter.html để parse các param trong URL
trên như sau:

```
'X-Goog-Algorithm':GOOG4-RSA-SHA256
'X-Goog-Credential': example@example-project.iam.gserviceaccount .com/20181026/us-central-1/storage/goog4_request
'X-Goog-Date':20181026T18 1309Z
'X-Goog-Expires':  900
'X-Goog-SignedHeaders': host
'X-Goog-Signature': 247a2aa45f16 9edf4d187d54e7cc46e4731b1e6273242c4f4c39a1d2507a0e58706e25e3a85a7dbb891d62afa849 6def8e260c1db863d9ace85ff0a184b894b117fe46d1225c82f2aa19efd52cf21d3e2022b3b868dc c1aca2741951ed5bf3bb25a34f5e9316a2841e8ff4c530b22ceaa1c5ce09c7cbb5732631510c2058 0e61723f5594de3aea497f195456a2ff2bdd0d13bad47289d8611b6f9cfeef0c46c91a455b94e90a 66924f722292d21e24d31dcfb38ce0c0f353ffa5a9756fc2a9f2b40bc2113206a81e324fc4fd6823 a29163fa845c8ae7eca1fcf6e5bb48b3200983c56c5ca81fffb151cca7402beddfc4a76b13344703 2ea7abedc098d2eb14a7 
``` 

Trong đó:

```
X-Goog-Algorithm: giải thuật được sử dụng để ký URL
X-Goog-Credential: thông tin về "credentical" được sử dụng để ký
X-Goog-Date: Thời gian mà Signed URL được ký
X-Goog-Expires: Hạn sử dụng của Signed URL, tính theo đơn vị giây, kể từ lúc ký
X-Goog-SignedHeaders: header
X-Goog-Signature: chuỗi xác thực
```

Signed URL có thể được sử dụng với các phương thức HTTP:

```
DELETE
GET
HEAD
PUT
POST
```

### 3. Các use case hay gặp

- Ứng dụng chia sẻ resource cho người dùng khác trong 1 khoảng thời gian, chỉ với URL, mà không cần phải cung cấp
  username/password để access vào resource đó.
- Bài toán private resource. Ví dụ chỉ có User đó mới có thể xem được các file ảnh, file data... từ hệ thống lưu trữ
  storage.
- Sử dụng Signed Url để cho phép upload trực tiếp file từ client lên hệ thống Cloud Storage, mà không cần phải trung
  gian qua Server của applicant. Nhằm tăng hiệu năng, tiết kiệm tài nguyên cho Server Backend.

### 4. Demo

AWS S3 là một service cung cấp dịch vụ lưu trữ lớn. Và AWS S3 có tích hợp sẵn chức năng Signed URL.   
Kịch bản là code Java sử dụng SDK của AWS, để generate Signed URL get data từ 1 file trên bucket.     
Code Java:

```java
  /**
 * @param amazonS3
 * @param bucketName
 * @param fileName
 * @return download link
 */
public static String getDownloadLink(AmazonS3 amazonS3,String bucketName,String fileName){
    String downloadLink="";
    if(bucketName.isEmpty()||fileName.isEmpty())return downloadLink;
    Date expiration=new Date();
    long expTimeMillis=new Date().getTime();
    expiration.setTime(expTimeMillis+TIME_MINUTES_EXPIRED*1000*60);

    try{
    GeneratePresignedUrlRequest generatePresignedUrlRequest=
    new GeneratePresignedUrlRequest(bucketName,fileName)
    .withMethod(HttpMethod.GET)
    .withExpiration(expiration);
    URL url=amazonS3.generatePresignedUrl(generatePresignedUrlRequest);
    downloadLink=url.toString();
    }catch(AmazonServiceException ase){
    }catch(AmazonClientException ace){
    LOG.error("Error Message: "+ace.getMessage());
    }
    return downloadLink;
    }
```

downloadLink example:

```
https://xinchaovietna222me.s3.ap-southeast-1.amazonaws.com/188?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20180710T065913Z&X-Amz-SignedHeaders=host&X-Amz-Expires=299&X-Amz-Credential=AKIAIP7Y2FP3U3AJWLPQ%2F20180710%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Signature=fc46c9d6cef32a94ee120dac5ab6a33c08e245256b979be977232b76c32e6926
```

parse

```
'X-Amz-Algorithm':AWS4-HMAC-SHA256
'X-Amz-Date':20180710T065913Z
'X-Amz-SignedHeaders':host
'X-Amz-Expires':299
'X-Amz-Credential':AKIAIP7Y2FP3U3AJWLPQ/20180710/ap-southeast-1/s3/aws4_request
'X-Amz-Signature':fc46c9d6cef32a94ee120dac5ab6a33c08e245256b979be977232b76c32e6926
```
