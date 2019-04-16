![Route53](https://blog.outsource.com/wp-content/uploads/2018/10/getting-started-on-aws-74-638.jpg)

## 1. Spec
Là một dịch vụ tên miền DNS     
### 3 chức năng chính
- Register domain names
- Route internet traffic to the resources for your domain
- Check the health of your resources

### Tính năng
- Kết nối hiệu quả với EC2, S3, ELB, Cloudfront
- Using Traffic Flow to Route DNS Traffic: Có thể sử dụng để redirect traffic, định tuyến enduser tới endpoint tốt nhất dựa theo: geoproximity, latency, health, and other considerations
- DNS failover: Route 53 tự động phát hiện sự cố của website và redirect truy cập user tới 1 locations khác. Khi bật tính năng này, thì
Route 53 sẽ thành 1 helth checking agent, để giám sát tính "availabale" của các endpoint
- Private DNS for Amazon VPC (A private hosted zone) dùng để làm DNS private cho các service trong cùng 1 VPC.  Ví dụ có thể tạo ra các record A, AAAA như db.example.com để DNS cho các query domain đến từ nội bộ VPC. Kết quả được trả về trước khi DNS ra ngoài global
![Create hosted zone](https://blog.andrewray.me/content/images/2017/09/hosted-zones.jpg)
- Domain Name Registration: trả tiền để thuê tên miền

### Các Routing policy:
- Simple routing policy: dùng cho 1 resource, định tuyến domain tới server 
- Failover routing policy: dùng để định tuyến traffic khi có server bị deactive, nó sẽ redirect tới server active
- Geolocation routing policy: định tuyến theo vị trí địa lý
- Geoproximity routing policy : định tuyến theo vị trí tài nguyên của mình, tùy ý
- Latency routing policy: được sử dụng với Multi Region, dùng để định tuyến tới region có đệ trễ thấp nhất
- Multivalue answer routing policy: định tuyến random, kết quả trả về là 1 trong 8 record của DNS
- Weighted routing policy: định tuyến truy cập tới các server theo hệ số khác nhau mà mình config


### Các API mà Route 53 cung cấp
- CreateHostedZone: tạo hosted zone chứa DNS data, sau khi tạo Hosted zone sẽ nhận được 4 name server
- GetHostedZone: lấy thông tin của Hosted Zone
- DeleteHostedZone
- ChangeResourceRecordSets
- ListResourceRecordSets
- CheckAvailability
- RegisterDomain


## 2. Demo  
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
