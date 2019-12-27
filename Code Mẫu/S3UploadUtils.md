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