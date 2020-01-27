# Amazon Route 53
## LAB

Tạo website static bằng S3, CloudFront và Route 53.     
1) Chuẩn bị domain      
Ví dụ: godaddy, namecheap   
2) Chuyển DNS về cho Route 53 quản lý   
- Create Hosted Zone        
- Type thông tin vào Domain Name (đây là tên domain của bạn)    
Sau đó vào phần quản lý domain để chỉnh lại phần DNS. Sau khi chỉnh lại phần DNS thì sẽ cần từ 24-48 giờ để hệ thống DNS được cập nhật 
3) Tạo bucket S3    
Sau khi đã tạo xong bucket tiếp theo cần enable chức năng static website hosting bằng cách chọn properties của bucket và click vào Static Website Hosting rồi chọn Enable website hosting

```
<bucket-name>.s3-website-<region>.amazonaws.com.
```
4) Tạo Cloudfront và link với Bucket    
Tạo mới một cloudfront distribution
- Origin domain name: Chọn bucket vừa đã tạo với amazon S3.
- Origin path: phần này sẽ quy định path mà bạn muốn cloudfront request tới content, nếu để là / thì sẽ root object bucketname/, nếu /folder_name thì tương đương với bucketname/folder_name.
- Restrict Bucket Access: Yes
- Alternate Domain Names: domain của bạn
Những phần còn lại để default nếu cần update thì-  sẽ edit lại.
Cuồi cùng click Create Distribution và đợi, sẽ mất 15-20 để cái destribution lúc này được deploy

5) Add alias cho cái domain về Cloudfront distribution      
- Vào Route 53, chọn hosted zones là domain của bạn và chọn create record set cho 2 type là A và AAAA, cả 2 type trên đều chọn Alias là Yes và Alias target đến cloudfront distribution đã được tạo.
Sau khi đã chọn xong thì click create.
![Cloud front dis](https://s3-ap-southeast-1.amazonaws.com/kipalog.com/s3aco9xwbv_Screen%20Shot%202016-12-19%20at%2011.08.06%20PM.png)
