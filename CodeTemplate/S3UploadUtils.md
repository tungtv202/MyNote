- Upload file có option set quyền public/private   
- Get link download (signed URL)  
- Delete file  
## 1. Basic
```java
import com.amazonaws.AmazonClientException;
import com.amazonaws.HttpMethod;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.*;
import com.tale.bootstrap.Bootstrap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.net.URL;
import java.util.Date;

public class S3UploadUtils {
    public static final Logger LOG = LoggerFactory.getLogger(S3UploadUtils.class);

    private static AmazonS3 s3Client(){
        final String accessKey = "aws access key";
        final String secretKey = "aws secret key";
        // return AmazonS3ClientBuilder.standard().build();
        return AmazonS3ClientBuilder.standard().withCredentials(
                new AWSStaticCredentialsProvider(new BasicAWSCredentials(accessKey, secretKey))).withRegion(Regions.AP_SOUTHEAST_1).build();
    };

    //    The time that download link has not expired
    private static final int TIME_MINUTES_EXPIRED = 5;

    /**
     * Upload file to AWS S3
     * isPrivate = true for private file. Ex: csv report
     * isPrivate = false for public file: Ex: avatar user
     *
     * @param awsS3Bucket AWS Bucket
     * @param fileName    File's name
     * @param bytes       Bytes
     * @param isPrivate   Private file
     * @return Url of file
     */
    public static String uploadFile(String awsS3Bucket, String fileName, byte[] bytes, boolean isPrivate) {
        CannedAccessControlList cannedAccessControlList = isPrivate ? CannedAccessControlList.Private : CannedAccessControlList.PublicRead;
        try {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(bytes.length);

            PutObjectRequest putObjectRequest = new PutObjectRequest(awsS3Bucket,
                    fileName, new ByteArrayInputStream(bytes), metadata);
            s3Client().putObject(putObjectRequest.withCannedAcl(cannedAccessControlList));
            return s3Client().getUrl(putObjectRequest.getBucketName(), putObjectRequest.getKey()).toString();
        } catch (AmazonClientException ace) {
            LOG.error(ace.getMessage(), ace);
            return null;
        }
    }

    /**
     * Upload public file to AWS S3
     *
     * @param awsS3Bucket AWS Bucket
     * @param fileName    File's name
     * @param bytes       Bytes
     * @return Url of file
     */
    public static String uploadFile(String awsS3Bucket, String fileName, byte[] bytes) {
        return uploadFile(awsS3Bucket, fileName, bytes, false);
    }

    /**
     * get download link for private file. That need token to download
     * bucketName same as folder name
     * fileName is unique per bucketName
     *
     * @param bucketName
     * @param fileName
     * @return download link
     */
    public static String getDownloadLink(String bucketName, String fileName) {
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
            URL url = s3Client().generatePresignedUrl(generatePresignedUrlRequest);
            downloadLink = url.toString();
        } catch (AmazonClientException ace) {
            LOG.error(ace.getMessage(), ace);
        }
        return downloadLink;
    }

    /**
     * Delete file on S3
     *
     * @param bucketName
     * @param fileName
     */
    public static void deleteFile(String bucketName, String fileName) {
        try {
            s3Client().deleteObject(new DeleteObjectRequest(bucketName, fileName));
        } catch (AmazonClientException ace) {
            LOG.error(ace.getMessage(), ace);
        }
    }
}
```

## 2. Sử dụng SSE-C để encrypt/decrypt object 
- Với cách này, chỉ có client chứa "key" mới có thể download/retrivew metadata của object được. Cho dù tài khoản root của AWS có full quyền, cũng không thể can thiệp, nếu không có key.
ref: https://docs.aws.amazon.com/AmazonS3/latest/dev/sse-c-using-java-sdk.html
### Code example
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
## 3. Note 
- Trường hợp OS chạy app java, nếu thỏa mãn 2 điều kiện sau, thì không cần phải khai báo access key, secret key trong code cho hàm s3Client()
  - OS là máy chủ AWS, có gán ROLE access tới S3 
  - OS có cài tool aws-cli, và có config accesskey, secret key.
- Với file được upload lên với giới hạn truy cập private, trường hợp muốn download thì cần generator link có token, khái niệm này là SIGNED URL. Và link có token sẽ chỉ valid trong 1 khoảng thời gian được cấu hình bởi biến TIME_MINUTES_EXPIRED

## 4. CopyObject sử dụng multi-thread - CompletableFuture
// S3 SDK không hỗ trợ copyObject cho nhiều object cùng lúc
```java

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3AsyncClient;
import software.amazon.awssdk.services.s3.model.CopyObjectRequest;
import software.amazon.awssdk.services.s3.model.CopyObjectResponse;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Component
public class Test implements CommandLineRunner {

    private static final String accessKey = "1234567";
    private static final String secretKey = "1345678/N0S8onuhk";

    final private S3AsyncClient s3AsyncClient;

    public Test() {
        this.s3AsyncClient = S3AsyncClient.builder()
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey)))
                .region(Region.AP_EAST_1)
                .build();
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println(123);
        List<CompletableFuture<CopyObjectResponse>> listFuture = new ArrayList<>();
        for (int i = 1; i < 100; i++) {
            CopyObjectRequest copyObjectRequest = CopyObjectRequest.builder()
                    .copySource("tungtv202-testversion" + "/" + "vnpayqr4.png")
                    .destinationBucket("tungexplorer.me")
                    .destinationKey(i + ".png")
                    .build();
            listFuture.add(s3AsyncClient.copyObject(copyObjectRequest));
        }

        CompletableFuture<Void> allFutures = CompletableFuture
                .allOf(listFuture.toArray(new CompletableFuture[listFuture.size()]));

        CompletableFuture<List<CopyObjectResponse>> allPageContentsFuture = allFutures.thenApply(v -> {

            return listFuture.stream().map(CompletableFuture::join)
                    .collect(Collectors.toList());
        })
//                .whenComplete((res, ex) -> {
//                    if (ex != null) {
//                        System.out.println("Oops! We have an exception - " + ex.getMessage());
//                    } else {
//                        System.out.println("done");
//                    }
//                })
                .exceptionally(ex -> {
                    System.out.println("Oops! We have an exception2 - " + ex.getMessage());
                    return null;
                });

        var resultList = allPageContentsFuture.get();
        if (CollectionUtils.isEmpty(resultList)) return;
        for (CopyObjectResponse e : resultList) {
            if (!"OK".equalsIgnoreCase(e.sdkHttpResponse().statusText().get())) {
                System.out.println("Copy object error");
            }
        }
        System.out.println(456);
    }
}
```
// Từ Java 9 trở đi CompleteTableFutre support delay giữa các async Executer
```java
CompletableFuture.delayedExecutor(5, TimeUnit.SECONDS)


 private CompletableFuture<ProductList> clientAsyncGetProduct(Store store, int page, String createdOnMax) {
        return CompletableFuture.supplyAsync(() -> productClient.filter(Utils.getxyzBaseUrl(store.getStoreAlias()), store.getAccessToken(), page, Constants.BACKUP_CLIENT_LIMIT
                , Constants.BACKUP_CLIENT_SORT_DEFAULT, createdOnMax), CompletableFuture.delayedExecutor(5, TimeUnit.SECONDS));
    }

```
. end