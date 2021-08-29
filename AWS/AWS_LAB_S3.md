---
title: AWS - S3
date: 2019-05-17 18:00:26
updated: 2019-05-17 18:00:26
tags:
    - aws
    - s3
    - object storage
category: 
    - aws
---

# AWS S3 - một service Cloud Storage

S3 là 1 service của AWS cho chức năng lưu trữ dữ liệu hướng Object

## 1. Thư viện

Tại thời điểm bài viết này, AWS đã cho ra bản SDK 2.0 cho Java, tuy nhiên đây là bản preview cho developer.

## 2. Tạo IAM

Cũng giống như nhiều SDK khác, Amazon AWS sử dụng các secret key để developer implement vô code.    
Sử dụng secret key để access tới service của Amazon, thay vì sử dụng username + password như trên giao diện web.    
Service quản lý việc này của Amazon là IAM. Để tạo và config role cho các secret key này bạn truy cập tại
đây: https://console.aws.amazon.com/iam

```java
// Example
String AWSAccessKeyId="AKIAIBGCWNEKIYZSKXTA";
String AWSSecretKey="LZjMW4t/udiEu8UXupg++I0mQsaXsm8Jb99upJBi";
```

## 3. Demo

### Step 1. Khởi tạo kết nối

Để thao tác được với AWS, Cần khởi tạo client trước.    
Nôm na có thể hiểu nhanh là bước này để verify kết nối, xem access key, secret key có đúng không.

```java
BasicAWSCredentials basicAWSCredentials = new BasicAWSCredentials(awsAccessKey, awsSecretKey);
AWSStaticCredentialsProvider credentialsProvider = new AWSStaticCredentialsProvider(basicAWSCredentials);
AmazonS3ClientBuilder s3ClientBuilder = AmazonS3ClientBuilder.standard().withRegion(awsRegion).withCredentials(credentialsProvider);
AmazonS3 s3connect = s3ClientBuilder.build();
```

Trong đó String awsRegion = "ap-southeast-1";   
Amazon S3 cung cấp nhiều Region để chứa dữ liệu.    
Có thể hiểu nhanh Region là vùng lưu trữ,Và AWS có hệ thống servers tại nhiều nơi trên thế giới.    
Bạn có thể chọn lấy 1 Region, nơi mà bạn thích để chứa dữ liệu của bạn. (Dựa theo vị trí địa lý chẳng hạn). Đây là danh
sách các Regions AWS cung cấp:

```
    GovCloud("us-gov-west-1", "AWS GovCloud (US)"),
    US_EAST_1("us-east-1", "US East (N. Virginia)"),
    US_EAST_2("us-east-2", "US East (Ohio)"),
    US_WEST_1("us-west-1", "US West (N. California)"),
    US_WEST_2("us-west-2", "US West (Oregon)"),
    EU_WEST_1("eu-west-1", "EU (Ireland)"),
    EU_WEST_2("eu-west-2", "EU (London)"),
    EU_WEST_3("eu-west-3", "EU (Paris)"),
    EU_CENTRAL_1("eu-central-1", "EU (Frankfurt)"),
    AP_SOUTH_1("ap-south-1", "Asia Pacific (Mumbai)"),
    AP_SOUTHEAST_1("ap-southeast-1", "Asia Pacific (Singapore)"),
    AP_SOUTHEAST_2("ap-southeast-2", "Asia Pacific (Sydney)"),
    AP_NORTHEAST_1("ap-northeast-1", "Asia Pacific (Tokyo)"),
    AP_NORTHEAST_2("ap-northeast-2", "Asia Pacific (Seoul)"),
    SA_EAST_1("sa-east-1", "South America (Sao Paulo)"),
    CN_NORTH_1("cn-north-1", "China (Beijing)"),
    CN_NORTHWEST_1("cn-northwest-1", "China (Ningxia)"),
    CA_CENTRAL_1("ca-central-1", "Canada (Central)");
```

// Có thể xem danh sách này trong com.amazonaws.regions .

### Step 2. Tạo bucketName

BucketName là gì? Có thể hiểu nhanh nó là tên 1 folder để chứa tất cả các dữ liệu của mình.     
Lưu ý: bucketName là unique với toàn hệ thống AWS (nhắc lại là toàn hệ thống aws, chứ không phải unique trong 1 tài
khoản).

```java
public static Bucket createBucket(AmazonS3 amazonS3, String bucketName) {
        Bucket bucket = null;
        try {
            bucket = amazonS3.createBucket(bucketName);
        } catch (AmazonServiceException ase) {
            LOG.error("Caught an AmazonServiceException, which means your request made it "
                    + "to Amazon S3, but was rejected with an error response for some reason.");
            LOG.error("Error Message:    " + ase.getMessage());
            LOG.error("HTTP Status Code: " + ase.getStatusCode());
            LOG.error("AWS Error Code:   " + ase.getErrorCode());
            LOG.error("Error Type:       " + ase.getErrorType());
            LOG.error("Request ID:       " + ase.getRequestId());
        } catch (AmazonClientException ace) {
            LOG.error("Caught an AmazonClientException, which means the client encountered "
                    + "a serious internal problem while trying to communicate with S3, "
                    + "such as not being able to access the network.");
            LOG.error("Error Message: " + ace.getMessage());
        }
        return bucket;
    }
```

Thực ra nguyên đoạn code dài ngoằng trên chỉ cô đọng trong 1 dòng:

```java
 Bucket bucket = amazonS3.createBucket(bucketName);
```

Cơ mà hãy cứ code sử dụng try catch như mình, để lấy được log lỗi cho chuẩn! Dễ debug.

### Step 3. Upload file to S3

Thực ra thì dùng từ "file" nó không được đúng lắm, với 1 hệ thống lưu trữ Object Storage thì không có khái niệm là "
file".      
Họ sử dụng từ "object". Cơ mà trong khuôn khổ demo code này mình viết văn theo cách mình nghĩ người khác dễ hiểu nhất.

```java
/**
     * upload file to s3
     * isPrivate = true for private file. Ex: csv report
     * isPrivate = false for public file: Ex: avatar user
     *
     * @param amazonS3
     * @param putObjectRequest
     * @param isPrivate
     * @return link to access file on s3
     */
    public static String uploadFile(AmazonS3 amazonS3, PutObjectRequest putObjectRequest, Boolean isPrivate) {
        String urlResult = "";
        if (putObjectRequest == null) return urlResult;
        try {
            if (isPrivate) {
                amazonS3.putObject(putObjectRequest.withCannedAcl(CannedAccessControlList.Private));
            } else {
                amazonS3.putObject(putObjectRequest.withCannedAcl(CannedAccessControlList.PublicRead));
            }
            urlResult = amazonS3.getUrl(putObjectRequest.getBucketName(), putObjectRequest.getKey()).toString();
        } catch (AmazonServiceException ase) {
        } catch (AmazonClientException ace) {
            LOG.error("Error Message: " + ace.getMessage());
        }
        return urlResult;
    }
    
```

Trong đó PutObjectRequest được khởi tạo bởi các thuộc tính sau:

```java
PutObjectRequest(String bucketName, String key, File file)
```

Hoặc

```java
PutObjectRequest(String bucketName, String key, InputStream input, ObjectMetadata metadata)
```

- bucketName: đã giải thích bên trên.
- key: fileName, có thể hiểu nhanh là tên của file, nằm trong folder. Và nó cũng là unique trong mỗi bucket.
- CannedAccessControlList.Private : khi 1 file upload lên S3, nếu không có config gì đặc biệt, default nó sẽ là private.

### Step 4 Get link download file từ S3 (có token)

(Thực tế kỹ thuật này được gọi là Signer URL)   
Với những file config policy là PUBLIC thì thật dễ dàng dể download, chỉ cần copy URL theo format na ná như sau:

https://s3-us-west-2.amazonaws.com/my-tungtv202-avatar/MyObjectKey  
là có thể download được mọi lúc mọi nơi.

Tuy nhiên với những file có policy là PRIVATE thì khi truy cập như vậy, sẽ gặp thông báo sau:

```xml
Error>
<Code>AccessDenied</Code>
<Message>Access Denied</Message>
<RequestId>AEE10DFAA27FEF26</RequestId>
<HostId>
ipPFZDboIzOCohRl4/RPe9I/IBQVn3esK+8mnGQO3yDKIPcatbnbl41SxC2oMUKPpt7WcG+toqk=
</HostId>
</Error>
```

Đoạn code dưới đây để getlink download (link có kèm token, token có thời hạn available).

```java
/**
     * get download link for private file. That need token to download
     * bucketName same as folder name
     * fileName is unique per bucketName
     *
     * @param amazonS3
     * @param bucketName
     * @param fileName
     * @return download link
     */
    public static String getDownloadLink(AmazonS3 amazonS3, String bucketName, String fileName) {
        String downloadLink = "";
        if (bucketName.isEmpty() || fileName.isEmpty()) return downloadLink;
        Date expiration = new Date();
        long expTimeMillis = new Date().getTime();
        expiration.setTime(expTimeMillis + TIME_MINUTES_EXPIRED * 1000 * 60);

        try {
            GeneratePresignedUrlRequest generatePresignedUrlRequest =
                    new GeneratePresignedUrlRequest(bucketName, fileName)
                            .withMethod(HttpMethod.GET)
                            .withExpiration(expiration);
            URL url = amazonS3.generatePresignedUrl(generatePresignedUrlRequest);
            downloadLink = url.toString();
        } catch (AmazonServiceException ase) {
        } catch (AmazonClientException ace) {
            LOG.error("Error Message: " + ace.getMessage());
        }
        return downloadLink;
    }
```

Example 1 download link có token:

```
https://xinchaovietna222me.s3.ap-southeast-1.amazonaws.com/188?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20180710T065913Z&X-Amz-SignedHeaders=host&X-Amz-Expires=299&X-Amz-Credential=AKIAIP7Y2FP3U3AJWLPQ%2F20180710%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Signature=fc46c9d6cef32a94ee120dac5ab6a33c08e245256b979be977232b76c32e6926
```

## 4. Sử dụng SSE-C để encrypt/decrypt object

- Với cách này, chỉ có client chứa "key" mới có thể download/retrivew metadata của object được. Cho dù tài khoản root
  của AWS có full quyền, cũng không thể can thiệp, nếu không có key.
  ref: https://docs.aws.amazon.com/AmazonS3/latest/dev/sse-c-using-java-sdk.html

### 4.1 Code example

```java

package tung.demo.ssec_s3;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.SdkClientException;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.*;

import javax.crypto.KeyGenerator;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

public class ServerSideEncryptionUsingClientSideEncryptionKey {
    private static SSECustomerKey SSE_KEY;
    private static AmazonS3 S3_CLIENT;
    private static KeyGenerator KEY_GENERATOR;

    public static void main(String[] args) throws IOException, NoSuchAlgorithmException {
        Regions clientRegion = Regions.AP_SOUTHEAST_1;
        String accessKey = "";
        String secretKey = "ga+tu8vB";
        String bucketName = "";
        String keyName = "test001.png";
        String uploadFileName = "D:\\yamaha.png";
        String targetKeyName = "*** Target key name ***";

        // Create an encryption key.
        KEY_GENERATOR = KeyGenerator.getInstance("AES");
        SecureRandom secureRandom = SecureRandom.getInstance("SHA1PRNG");
        secureRandom.setSeed("TUNGTUNGTUNG".getBytes());
        KEY_GENERATOR.init(256, secureRandom);
        SSE_KEY = new SSECustomerKey(KEY_GENERATOR.generateKey());

        try {

            S3_CLIENT = AmazonS3ClientBuilder.standard()
                    .withCredentials(new AWSStaticCredentialsProvider(new BasicAWSCredentials(accessKey, secretKey)))
                    .withRegion(clientRegion)
                    .build();

            // Upload an object.
            uploadObject(bucketName, keyName, new File(uploadFileName));

            // Download the object.
//            downloadObject(bucketName, keyName);

            // Verify that the object is properly encrypted by attempting to retrieve it
            // using the encryption key.
            retrieveObjectMetadata(bucketName, keyName);

            // Copy the object into a new object that also uses SSE-C.
//            copyObject(bucketName, keyName, targetKeyName);
        } catch (AmazonServiceException e) {
            // The call was transmitted successfully, but Amazon S3 couldn't process
            // it, so it returned an error response.
            e.printStackTrace();
        } catch (SdkClientException e) {
            // Amazon S3 couldn't be contacted for a response, or the client
            // couldn't parse the response from Amazon S3.
            e.printStackTrace();
        }
    }

    private static void uploadObject(String bucketName, String keyName, File file) {
//        PutObjectRequest putRequest = new PutObjectRequest(bucketName, keyName, file);
        PutObjectRequest putRequest = new PutObjectRequest(bucketName, keyName, file).withSSECustomerKey(SSE_KEY);
        S3_CLIENT.putObject(putRequest);
        System.out.println("Object uploaded");
    }

    private static void downloadObject(String bucketName, String keyName) throws IOException {
        GetObjectRequest getObjectRequest = new GetObjectRequest(bucketName, keyName).withSSECustomerKey(SSE_KEY);
        S3Object object = S3_CLIENT.getObject(getObjectRequest);

        System.out.println("Object content: ");
        displayTextInputStream(object.getObjectContent());
    }

    private static void retrieveObjectMetadata(String bucketName, String keyName) {
        GetObjectMetadataRequest getMetadataRequest = new GetObjectMetadataRequest(bucketName, keyName)
                .withSSECustomerKey(SSE_KEY);
        ObjectMetadata objectMetadata = S3_CLIENT.getObjectMetadata(getMetadataRequest);
        System.out.println("Metadata retrieved. Object size: " + objectMetadata.getContentLength());
    }

    private static void copyObject(String bucketName, String keyName, String targetKeyName)
            throws NoSuchAlgorithmException {
        // Create a new encryption key for target so that the target is saved using SSE-C.
        SSECustomerKey newSSEKey = new SSECustomerKey(KEY_GENERATOR.generateKey());

        CopyObjectRequest copyRequest = new CopyObjectRequest(bucketName, keyName, bucketName, targetKeyName)
                .withSourceSSECustomerKey(SSE_KEY)
                .withDestinationSSECustomerKey(newSSEKey);

        S3_CLIENT.copyObject(copyRequest);
        System.out.println("Object copied");
    }

    private static void displayTextInputStream(S3ObjectInputStream input) throws IOException {
        // Read one line at a time from the input stream and display each line.
        BufferedReader reader = new BufferedReader(new InputStreamReader(input));
        String line;
        while ((line = reader.readLine()) != null) {
            System.out.println(line);
        }
        System.out.println();
    }
}
```

.
