# AWS ElastiCache 
// Dịch vụ cung cấp Redis, NameCached trên AWS

## 1.1 Sự khác biệt giữa Memcached với Redis
3 khác biệt cơ bản

- Memcached thì cung cấp dữ liệu dạng key/value đơn giản hơn. Đơn giản chỉ là chuỗi string hoặc binary data. Trong khi Redis thì phức tạp hơn, nó còn có set, lists, zset, hash… dữ liệu có nhiều loại hơn, có tổ chức hơn, có sort, có rank.
- Memcached thì không hỗ trợ persis data (dữ liệu không được save, không được snapshoot, 1 khi đã mất là mất). Trong khi Redis thì có cơ chế backup, có cơ chế snapshoot và lưu vào disk, có thể tạo ra 1 cluster Redis mới bằng việc khởi tạo từ bản snapshoot được lưu.
- Memcached thì có thể dựng nhiều node (trong sách thấy ghi là tối đa 20 node) để tạo thành 1 cluster. Còn Redis thì mỗi 1 cluster là 1 single node. Nhưng nhiều cluster thì có thể group lại thành 1 nhóm (Redis replication group).

## 1.2 Scaling
ElasticCache cho phép việc scaling theo chiều ngang.    
Bị hạn chế scaling theo chiều dọc.  

## 1.3 Khi có node lỗi, ElastiCache làm gì?     
Nó tự phát hiện ra lỗi, khi có lỗi, nó sẽ thay thế và tự thêm mới 1 cluster. Trong suốt thời gian này, truy vấn sẽ được gửi tới database => database sẽ bị tăng lưu lượng.  
Riêng với ElastiCache chạy Redis, có 1 tính năng của Amazon là Multi-AZ replication group, nếu tính năng này được bật, thì:     
- Khi primary node bị lỗi => read replica sẽ được tự động đẩy lên làm primary
- Node lỗi => sẽ tự động được thay thế bởi 1 node mới. Vậy primary node là gì? Read replica node là gì? Primary node đó là node chạy Redis với đủ quyền read lẫn write, còn read replica thì chỉ có quyền read, 1 con primary có thể có tới 5 con read replica, mục đích để san sẻ tải. 
![EC](https://images.viblo.asia/d6e4b83d-c326-4ad2-a2a6-51473680d636.jpg)

ElastiCache có kết hợp với DNS của Amazon, để khi node mới thay thế node lỗi, thì node mới sẽ có IP, policy của node cũ luôn, ứng dụng của developer sẽ được chạy thông suốt, mà developer không phải config lại cái gì. Lưu ý: việc sao chép data giữa các cluster là không đồng bộ và sẽ mất 1 khoảng thời gian delay.

## 1.4 ElastiCache backup và recovery data thế nào? 
Với Memcached thì không hỗ trợ tính năng này, khi tạo mới 1 Memcached cluster, thì sẽ luôn là empty data.       
Với Redis, ElastiCache cung cấp cửa sổ để developer cấu hình lịch định kỳ để tạo các bản snapshot, các file backup này được lưu trữ trong S3. Các bản snapshots thực hiện thủ công manual, sẽ được lưu trữ mãi mãi, cho tới khi bạn xóa nó.

## 1.5 Access Control
Về việc cấp quyền access, thì ElastiCache dựa theo NETWORK. Nghĩa là nó dựa vào địa chỉ IP, subnetmask để xây dựng lên các chính sách network, việc access sẽ dựa vào security groups này.      
Có thể hạn chế xâm nhập vào bằng cách cấu hình trong ACL (Acess List) .        
Về việc manage, sử dụng service IAM, AWS Identity của Amazon để định nghĩa các chính sách cho các AWS User.

# Amazon Route 53
Là một dịch vụ tên miền DNS     
## chức năng chính
- Register domain names
- Route internet traffic to the resources for your domain
- Check the health of your resources

## Tính năng
- Kết nối hiệu quả với EC2, S3, ELB, Cloudfront
- Using Traffic Flow to Route DNS Traffic: Có thể sử dụng để redirect traffic, định tuyến enduser tới endpoint tốt nhất dựa theo: geoproximity, latency, health, and other considerations
- DNS failover: Route 53 tự động phát hiện sự cố của website và redirect truy cập user tới 1 locations khác. Khi bật tính năng này, thì Route 53 sẽ thành 1 helth checking agent, để giám sát tính "availabale" của các endpoint. (Cần tạo policy healcheck, sau đó vào hostzone add record A primary và secondary). Điểm khác biệt với ELB?
- Private DNS for Amazon VPC (A private hosted zone) dùng để làm DNS private cho các service trong cùng 1 VPC. 
- Domain Name Registration: trả tiền để thuê tên miền

## 2.3 Các Routing policy:
- Simple routing policy: dùng cho 1 resource, định tuyến domain tới server 
- Failover routing policy: dùng để định tuyến traffic khi có server bị deactive, nó sẽ redirect tới server active (DNS Failover)
- Geolocation routing policy: định tuyến theo vị trí địa lý
- Geoproximity routing policy : định tuyến theo vị trí tài nguyên của mình, tùy ý
- Latency routing policy: được sử dụng với Multi Region, dùng để định tuyến tới region có đệ trễ thấp nhất
- Multivalue answer routing policy: định tuyến random, kết quả trả về là 1 trong 8 record của DNS
- Weighted routing policy: định tuyến truy cập tới các server theo hệ số khác nhau mà mình config

# AWS Lambda
Sự khác biệt giữa EC2 và Lambda là gì? 
- Lambda là serverless (không có các tài nguyên như RAM, CPU, Disk...), còn EC2 thì ngược lại, nó là server. 

Lambda có công dụng gì? 
- Lambda chỉ để chạy các đoạn code đã được developer lập trình. Nghĩa là sẽ không thể cài đặt được software, library, tool của bên thứ 3 như vẫn hay thường cài trên 1 server truyền thống. 
Có vẻ giống với hosting của php...

Lambda support những ngôn ngữ gì? 
- Hiện tại thì: Node.js (JavaScript), Python, Java (Java 8 compatible),  C# (.NET Core). 

Một vài điểm nổi bật của Lambda
- Không phải lo lắng về việc scale server, vì nó là serverless. 
- Nó tận dụng được hệ thống Infra của AWS, nên có thể xem là không cần quan tâm tới các tài nguyên vật lý cho ứng dụng. 
- Cách giới hạn scale của Lambda là setup giới hạn hóa đơn thanh toán
- Khi deploy code trên Lambda nếu code không chạy, thì sẽ không bị mất tiền
- Code sau khi được deploy lêm Lambda, tùy thuộc vào traffic, và effort của request mà tính tiền.
- Cần phải tính toán về RAM và khai báo cho ứng dụng trước khi chạy. Việc tính toán CPU là tự động.
- Lambda sử dụng BeanStalk (1 dịch vụ khác của AWS) để deploy code. Và code được lưu trữ ở S3
## Use case 
- combo kết hợp Lambda + API Gateway 

# DynamoDB
- Dynamic DB: 10 000 beyond
- Stored on SSD storage

# EC2 
## EC2 Enhanced Networking 
- Lợi ích của SR-I/OV :
    - Higher Packet per Second (PPS) performance (inter-instance)
    - Lower inter-instance latencies
    - Very low network jitter
- Enhanced networking requirements:
    - Instances be launched from an HVM AMI (not PV)
    - Is only supported in a VPC
- Enhanced networking is not suppored on all EC2 instances
- Enhanced networking does NOT cost extra
- Enhanced networking can be enabled on Instance-store backed or EBS-backed EC2 instances

## EC2 Bootstrapping 
- Là user data
- Pass script chạy sau khi EC2 instance launched (ví dụ như script sau khi chạy thì update OS, run shell script...).

## EC2 - Placement Groups 
- Là một tính năng cho phép các EC2 liên quan có thể kết nối với nhau với băng thông cao, độ trễ thấp, trong cùng 1 AZ (cả 3 loại đều cùng 1AZ)
- Yêu cầu cùng 1 AZ
- Có thể sử dụng Enhanced networking instances trong Placement groups
- There are only specific instance type which can be launched inside the placement group
- We cannot move existing instance into placement group, in such case we need to create an AMI of instance and launch new instance from that AMI inside the p group
- Maximum network throughput traffic between two instance in placement group is limited by the slower of the two instance
- Có 3 type tạo placementGroup: cluster, partition, spread. 
    - Cluster: cho performance về network cao nhất (do bố trí vật lý gần nhau) => Chỉ triển trong cùng 1 AZ
    - spread: là một nhóm các instances được đặt trên phần cứng cơ bản riêng biệt, có thể trải rộng trên nhiều AZ. (phù hợp hệ thống nhỏ nhưng thích HA)
    - partition: độc lập. Có thể có tối đa 7 partitions cho mỗi Availability Zone và có thể trải rộng trên nhiều Availability Zones trong cùng một Region.
(phù hợp hệ thống lớn cần HA)
- The name that we specify for placement group must be unique across your AWS account.
- AWS recommends instances with same type to be launched within a placement group
- We cannot merge placement groups
- Đi kèm với Instance support Enhance Networking. (tức là chỉ instance HVM ?)

## EC2 - Bastion Host 
- 1 Computer được cấu hình đặc biệt, thuộc miền external/ public (DMZ) hoặc bên ngoài firewall, hoạt động như một server trung gian, cho phép bạn connect vào các Instance nằm trong Private Subnet
- Trường hợp Instance bị terminated, nhưng Auto Scaling Group đang launches, thì Elastic IP sẽ được đính lên cho instances mới

## EC2 - Spot instances
- Đấu thầu để được chạy instances (các tài nguyên mà AWS đang dư thừa), giá rẻ hơn Instances on-demaind rất nhiều. Tuy nhiên khi nào có người khác trả giá cao hơn giá mình thầu, thì instance đó sẽ bị terminated
- Spot instance không đảm bảo luôn luôn khả dụng, nhưng giá rẻ

## EC2 - Rerserved Instances 
- Là Instances on-demand, nhưng có thuê bao, trả trước sẽ có giá rẻ hơn. Ví dụ đảm bảo dùng trong 12 tháng.
- They can be used to launch AS Group instances or standalone ones
- Có thể Reversed theo lịch, ví dụ thuê instance sẽ được chạy auto scale vào 1 ngày hàng tuần...

## EC2 - IAM Roles
- Gán quyền để application access read/write S3, SQS, DynamoDB, SNS...
- Default IAM Roles cho phép EC2 instances access vào các service khác 
- You can add the IAM role while the instance is running 

## EC2 - Charge
- Được tính tiền từ lúc bắt đầu boot ec2 (ko phải là sau khi instand đã start xong). Tới lúc shutdown hoàn toàn
- Mỗi lần bật tắt instance, sẽ bị tính tiền tối thiểu cho 1 tiếng. Ví dụ trong 10 phút, bật tắt instance 2 lần, thì bị tính tiền 2 tiếng sử dụng.
## Error
- Một vài lỗi khiến EC2 bị terminate khi launch:
    - AMI thiếu 1 số part
    - Limit volume EBS
    - Bản snapshot EBS bị lỗi
- Để tìm lỗi termination:
    - From Console: Go to Instances (select the instance) -> Description tab -> State Transition reason
    - From CLI use the "describe-instance command

- Lỗi: Insufficient Instance Capacity : aws hết tài nguyên, đợi, hoặc reserved instances

# Elastic Network Interface
- Là card mạng ảo, được đính vào EC2 (vd: eth0, eth1...)
- Khi EC2 bị terminated => Nếu ENI tạo bằng console thì cũng terminate theo, nếu tạo bằng command line thì ko bị terminated
- Có thể được cấu hình khi: instance running, stopped, launched
- 1 ENI chỉ được cho 1 Insntace, nhưng 1 instance có thể attached nhiều ENI
- Subnet có thể khác nhau nhưng phải chung VPC, chung AZ
- Instance type khác nhau thì sẽ có số ENIs có thể đính vào khác nhau

# RDS
- DB instance class maximum size: 6TB
- Service cung cấp hệ quản trị SQL: MySQL, PostgreSQL...
- HA luôn được implies Multi-AZ
- Read Replicas có thể được sử dụng để scale READ performance, tuy nhiên
    - Không thể với WRITE
    - Có sự bất đồng bộ giữa các node
- AWS quản lý fully managed service, tức là dev ko thể can thiệp được vào OS, instance chạy RDS => chỉ access được vào RDS enginer
- Primary và standby có thể khác AZs (nhưng phải cùng chung region)
- Không nên sử dụng IP address làm point để kết nối, mà nên sử dụng endpoint 
- Có thể sử dụng CloudWatch Alarm để monitor metric, và alarm
- CloudTrail để logs all AWS RDS API
- Có thể read replica (được với MySQL, MariaDB, PostgreSQL (MyMaPo) )
- Quá trình scale, hay chuyển giao primary-standby sẽ `mất vài phút`
- Khi chạy Multi-AZ RDS thì chế độ backups và snapshots sẽ được tự động chạy 
- Không thể read/write tới Standby RDS DB instance
- Tất cả RDS db engines đều có thể có dung lượng lưu trữ lên > 6GB, trừ MS SQL
- MS SQL DB engine can have storage capacity up to 4TB
- Không thể giảm size của RDS sau khi chạy, chỉ có thể tăng
- Amazon RDS Provisioned IOPS Storage được dùng để tăng performance (ứng dụng nào yêu cầu I/O cao, thì nên dùng )
- Việc upgrade version RDS có 2 loại
    - Major version Upgrades - admin phải upgrade manual, cant revert
    - Minor version Upgrades
- Không thể restore 1 bản snapshot tới 1 instance đã tồn tại DB (cần tạo mới, và restore vô cái mới)

- Không thể thay đổi Storage type (magnetic, Provisioned IOPS, General purpose) trong suốt quá trình restore thực thi
- Nếu set retention period = 0, tương đương tắt chế độ automatic backups. 
- Khi bạn restore 1 DB instance, chỉ có các tham số mặc định và Security groups đã được liên kết mới có thể restore
- Sau lưu tự động hiện tại chỉ support InnoDB , MySQL (ko support cho MyISAM)
- Tính năng khôi phục theo thời gian Point-In-Time chỉ được hỗ trợ cho MySQL, InnoDB
- InnoDB có vẻ là chiến lược của AWS
- Aurora là RDS mà tự động HA tới 3 AZ
- Encrypting existing RDS is not currently supported
- Achieved using asynchronous replication


# S3 
- S3 Versioning once enabled, versioning cannot be disabled, only suspended

## Encrypt
- Có 2 cách để mã hóa dữ liệu được lưu trữ trên S3 buckets
    - Client side encryption (được mã hóa dưới client, trước khi upload lên S3)
    - Server Side Encryption (SSE)
        - Data được mã hóa bởi S3 trước khi storage disks của S3 
        - Data được giải mã khi bạn download nó 
- Tại bất kỳ thời điểm nào, cũng chỉ có thể áp dụng 1 loại mã hóa 
- Tùy thuộc vào cách quản lý khóa mã hóa, có 3 loại SSE
    - SSE-S3: S3 quản lý encryption keys
    - SSE-KMS: sử dụng KM keys
    - SSE-C: Client cung cấp keys
- Glacier: chỉ có thể read

## Performance 
- Nếu bucket có lượng truy cập dưới 100 PUT/LIST/DELETE cho mỗi giây, hoặc dưới 800 GET request mỗi giây, thì ko cần phải cấu hình gì cho S3 để nâng performance cả
- Ngược lại: 
    - Random prefix để chúng được lưu vào các phân vùng khác nhau (hình như version mới nhất thì ko cần phải random nữa, mà S3 tự động performance)
    - Sử dụng CloudFront để phân phối tải tới S3
- Versioning is disable default

- Bạn có thể truy suất data từ Glacier theo nhiều cách
    - Expedited: 1-5 mts
        - More expensive
        - Use for urgent requests only
    - Standard: 3-5 Hrs
        - Less expensive than Expedited
        - You get 10GB data retrieval free/ month
    - Bulk retrieval: 5-12 Hrs
        - Cheapest
        - Use to retrieve large amounts up to Petabytes in a day

## S3 Cross Region Replication
- AWS sẽ không replicate dữ liệu ra ngoài region, nó chỉ sao chép trong nhiều facilities (AZ) (nhưng có feature cross region)
- Mặc định, tất cả objects sẽ gán quyền private, và chỉ có owner mới có thể access
- Để chia sẻ object bạn có 2 cách
    - Set quyền object public 
    - Tạo pre-signed URL 

- bucket 
    - global name, unique across all AWS accounts
- object
    - 0 bytes - 5 TB
    - Dung lượng lớn nhất cho 1 PUT request upload là 5GB (nếu dung lượng lớn hơn 100MB, cân nhắc nên sử dụng Multipart Upload)
- Data tự động được replicated trong 1 region

- Security
    - ACL
    - BucketPolicies
        - IP address range
        - AWS account
        - Objects with a specific prefix
    - Encryption
- Có thể xài kèm Athena để query SQL trên S3 (dạng sheet)
- Signed URL
- Có chức năng Restric Viewer
- Từ Standard sang IA phải ít nhất 30 ngày, nhưng từ Standard sang Glacier thì whenever
## S3 Cross Region Replication
- Versioning must be enabled on both the source and destination buckets
- Files in an existing bucket are not replicated automatically, all new and updated files will be replicated automatically
## S3 Versioning
- Tốn tiền hơn, 1 object có thể có nhiều version khác nhau, 
- Cách để vào mỗi version là url có thêm 1 parameter `versionId=xxx`
- Xóa logic là chỉ đánh dấu delete marker
- Xóa vĩnh viễn thì ko khôi phục được
## S3 Transfer Acceleration
- Khi upload object, sử dụng 1 endpoint khác với endpoint trực tiếp. Lúc đó aws sẽ route traffic sao cho upload được đưa tới `edgate location` để có tốc độ cao nhất
- Có nét tương đồng với CloudFront, nhưng có lẽ Cloudfront hợp cho việc download hơn. Theo khuyến cáo thì khi data nhiều tới GB,TB thì nên sử dụng S3 Transfer Acceleration
- [https://stackoverflow.com/questions/36882595/are-there-any-difference-between-amazon-cloudfront-and-amazon-s3-transfer-accele/36927340](https://stackoverflow.com/questions/36882595/are-there-any-difference-between-amazon-cloudfront-and-amazon-s3-transfer-accele/36927340)

## S3 Intelligent-Tiering
- Object được lưu đồng thời trên cả 2 tier. 1 cho frequent, 1 cho infrequent, sau 1 khoảng thời gian aws theo dõi, nó sẽ tự động move các object ít truy cập về tier infrequent. Và ngược lại. (ko tốn phí, nhưng tốn fee trước đó)
# Storage Gateway
- dùng cho hệ thống lai (on premises vs on demand)
- hay đi kèm vs NFS (base on S3) (ngoài ra có VolumeGateway (base on EBS)...)
- Import to S3 or Export from S3
- Snowball
    - 80TB, no compute
- Snowball Edge
    - 100TB, has compute
- Snowmobile
    - 100PB, semi-truck
- Type:
    - File Gateway: NFS or SMB
    - Volume Gateway: 
        - Stored: EBS - 1GB-16TB
        - Cached: S3 - 1GB- 32GB
    - Tape Gateway
# Snowball
- Là thiết bị vật lý. Nó như 1 cái máy tính có tích hợp ổ cứng di động, ship về on premiss, xong copy data vào nó, rồi ship về data center của Amazon, để copy lại. Dùng trong case mà data migrate rất rất lớn. Mà việc upload tốn nhiều thời gian.
- Snowball support mã hóa KMS, nên không lo về security.
- Khi nào snowball ship về amazon xong, nhân viên sẽ upload data từ snowball vào bucket khách hàng, khi thành công sẽ có SNS
- Snowball là giải pháp vận chuyển dữ liệu ở cấp độ petabyte sử dụng các thiết bị được thiết kế bảo mật để truyền lượng dữ liệu lớn vào và ra khỏi Đám mây AWS.
- Snowball can:
    - import to S3
    - export from S3

# VPC
## 1. Security
### Security groups vs Network ACLs
|  Security groups  |  Network ACLs | 
|---|---|
|  instance level | subnet level  | 
|  stateful | stateless  |  

- Security groups STATEFUL: nếu đồng ý cho phép chiều đi vào, thì chiều đi ra cũng sẽ được đồng ý, ngược lại
- Network ACL STATELESS: Nếu có rule đồng ý cho kết nối tới port 22 đi vào, thì cũng phải có rule cho phép đi ra

### Security groups
- stateful
- Có thể sử dụng Security Group names như 1 khai báo "source" hoặc "destination" cho 1 Security Group khác
- Chỉ có rule allow (không thể khai báo rule deny, nếu không khai báo allow thì mặc định traffic là deny)
- Default là deny tất cả traffic inbound, và allow tất cả traffic outbound

### NACL
- stateless
- supports allow rules and deny rules
- Hình như là default allow all cho EC2 cùng subnet
- You can associate network ACL with multiple subnets, however subnet can only associate with one ACL at a time

## 2. VPC peering 
- Dùng để kết nối giữa các VPCs. Ví dụ: kết nối các EC2 ở các Region khác nhau (kể cả khác Account)
- Hạn chế:
    - không thể định tuyến gói tin từ VPC B tới VPC C thông qua VPC A 
    - không thể khởi tạo, nếu như có sự trùng lặp, conflict CIDR blocks giữa các VPC (ví dụ: cùng chung dải mảng 10.0.0.0/16)
    - giữa 2 VPC, tại cùng 1 time, chỉ có thể có duy nhất 1 VPC peering
## 3. AWS Direct Connect
- AWS cung cấp 1 số địa điểm (office vật lý) để khách hàng có thể tới trực tiếp cắm dây mạng vào để kết nối tới hệ thống của AWS. => giảm chi phí truyền tải băng thông trên internet . 
- Use case:
    - Thao tác với bộ dữ liệu lớn
    - Nguồn cấp dữ liệu theo thời gian thực
    - Môi trường lai
- Chỉ cung cấp ở 1 số địa điểm vật lý nhất định trên toàn thế giới

## 4. Virtual Private Gateway
## 5. Configuration
- Khi config VPC sử dụng VPC wizard và khai báo VPN-Only and VPN access implies (tức chỉ có VPN mới truy cập vào được). Sẽ có các thông số sau:
    - Không có public subnet
    - Không có NAT instance/gateway
    - Tạo 1 Virtual Private Gateway (ko có EIP)
    - Tạo 1 VPN connection
## 6. VPC CIDR Block 
- Không thể thay đổi size CIDR Block sau khi tạo. Nếu muốn tăng size thì tạo 1 VPC mới (cần thiết kế cẩn thận từ đầu)

### 7. VPC Folow log
- Nếu VPC Peering đang được bật, và chủ peering là Account khác, thì ko thể bật `flow logs`
- cannot tag a flow log
- after flow log is created, you canot change its configuration
- (1 số IP đặc biệt, DHCP) sẽ ko được monitor
### 8. Nat gateway
- 1 cải tiến của Nat Instance

### VPC Endpoint
- Không có VPCEndpoint cho RDS
- Chỉ có S3 và dynamodb là có Gateway VPC endpoitn
- còn lại là Interface VPC endpoint
# ELB
- ELB có thể chạy khác Region được, nhưng cần phải có Route 53
- Phân phối traffic cho các EC2 ở nhiều AZ 
- Sticky sessions 
- X-Forwarded-For:
    - get client IP address
    - get previous Request IP Address
    - get Load Balancer IP Address
- Trả về `504` nếu EC2 ko có response
- ko có IPv4
## 1. Các cách để monitoring ELB
- AWS Cloud Watch:
    - ELB gửi ELB metric tới Cloud Watch mỗi 1 phút 
    - ELB gửi metric mỗi khi có request tới ELB
    - Có thể config triger SNS notification khi ELB đạt tới 1 ngưỡng nào đó 
- Access Logs:
    - Default tắt
    - Có thể config chọn S3 lưu trữ log
    - Có thể có được các thông tin như requester, thời gian request, IP request, loại request...
    - Sẽ không bị charged thêm tiền nếu đã trả tiền cho S3
- AWS Cloud Trail
    - Để capture all API calls tới ELB
    - Có thể lưu trữ log trên S3 
## 2. Config
- Nếu không có config đặc biệt, ELB sẽ sử dụng config của ELB gần nhất để define
- Để cho phép Backend EC2 (Web layer) biết được thông tin chi tiết của Originator/ requester (ví dụ: source IP address, port...) bạn có thể:
    - Enable Proxy Protocol for TCP/SSL Layer 4 listeners as supported on the ELB
    - Enable X-Forewaded-For headers for HTTP/HTTPS listeners on the ELB
- Mặc định ELB được bật để load balancer giữa các AZ 
- The ELB hỗ trợ các SSL protocols:
    - TLS 1.0, TLS 1.1, TLS 1.2, SSL 3.0
    - It does not support TLS 1.3 or SSL 2.0 (which is deprecated)
## 3. Type
- ALB => layer 7 of OSI
- NLB => Layer 4 of OSI
- CLB => layer 7 mix 4
## 4. ELB - Proxy Protocol
- Trước khi bật tính năng Proxy Protocal thì cần chắc chắn rằng trước Load Balancer chưa có proxy server

## 5. ELB - Sticky sessions
- Trường hợp BE instance bị chết, ELB sẽ định tuyến traffic tới 1 instance mới, khỏe mạnh, và sticky session trên instance mới. (kể cả khi instance cũ đã khỏe lại)
- For ELB, duration based, cookie stickiness

## 6. Connection Draining 
- Mặc định ELB sẽ check helth của EC2, nếu check lỗi, sẽ đưa EC2 ra `out of service`, có thể sẽ khởi tạo 1 EC2 khác thay thế. Tuy nhiên trong 1 số trường hợp, EC2 được admin chủ động maintaince gì đó (ví dụ để update, upgrade) dẫn tới việc "unhelth", thì ELB sẽ tạm ignore case này, trong khoảng thời gian này
- Is disabled by default
- Default, wait 300 seconds

## 7. SNI and ELB
- Server Name Indication (SNI) là một phần mở rộng của giao thức mạng máy tính TLS . Nó cho phép một máy chủ có thể sử dụng nhiều chứng chỉ SSL cho nhiều tên miền trên cùng một địa chỉ IP mạng WAN. Nó giống như việc sử dụng https cho nhiều tên miền cùng sử dụng chung một địa chỉ IP để tiết kiệm
- Elastic Load Balancing không hỗ trợ Server Name Indication (SNI) => cần tìm giải pháp
- X-Forwarded-For is supported with HTTP/HTTPS listeners only
- Proxy protocol is supported with TCP/SSL listeners only

## 8. ELB-Pre-Warming
ELB Scaling:
- Thời gian để ELB phát hiện được việc tăng traffic là khoảng 1-7p
- ELB không được thiết kế để queue requests
- Trả về lỗi 503, nếu ELB không thể handle được request
- Nếu traffic có thể tăng quá nhanh, hơn 50%, thì cần contact AWS để pre-warm
- Khi ELB scales, nó sẽ update DNS record với danh sách IP mới
- Để chắc chắn clients đang có sự gia tăng về capacity, ELB sẽ gửi TTL tới DNS Record mỗi 60s

# Kinesis
- Kinesis Stream  
    - data stored for 24 hours by default
    - data stored in shards
    - data consumers (ec2 instances) turn shards into data to analyze
    - 5 transactions per second for reads, maximum total rate of 2 MB/second up to 1,000 records for writes
- Kinesis Firehose
    - Automated
    - no dealing with shards
- Kinesis Analytics 
    - Way of analyzing data in Kinesis using SQL-like queries

# SQS
- messages are 256KB in size
- kept 1 minute to 14 days, default 4 days
- Visibility Timeout
  - if job is not processed within timeout time, message becomes visible again
  - if message is processed within that time, message is deleted
  - maximum invisible time is 12 hours
- Standard Queues
    - nearly-unlimited number of transactions per second
    - guarantee message is delivered at least once
    - more than one could be delivered out of order

- FIFO Queues
    - messages sent and received in order they arrive
    - delivered once and remains available until consumer processes and deletes it
    - SQS FIFO, chỉ có 1 process được access

# SWF
- Task is assigned only once and is never duplicated
- assigns tasks and monitors progress
- workers/deciders don't track execution state, run independently, and scale quickly
- parameters described in JSON
- maximum workflow is 1 year, always measured in seconds

## SWF Domains
- workflow, activity types, workflow execution all scoped to a Domain
- Domains isolate set of types, executions, and task lists from others in same account

## SWF Actors
- SWF Workflow Starters
  - application to start/initiate workflow
  - could be website or mobile app, for example

- SWF Decider
  - program that controls coordination of tasks
  - task ordering, concurrency, scheduling according to application logic

- SWF Workers
  - program/person that interacts with SWF
  - gets task
  - process receives tasks
  - returns result

# Cloudwatch
- Có Cloudwatch Agent
- Ko monitor được RAM (instance window monitor hạn chế hơn instance linux)
- Standard Monitoring = 5 minutes
- Detailed Monitoring = 1 Minute (mất nhiều fee hơn)

# Auto Scaling
- Simple Scaling - Ví dụ khi CPU tới 1 ngưỡng nào đó thì scaling
- Step Scaling - Ví dụ: khi có 2 instance, thì CPU tới ngưỡng X sẽ kickoff, nhưng khi 3 instance thì tới ngưỡng Y mới kickoff
- Target Tracking Scaling - so complex

# Developer Tools
- CodeStar - Project managing of code for developers
- CodeCommit - Place to store code (source control), private git repository
- CodeBuild - Compiles, tests code and build packages ready for deployment
- CodeDeploy - Deployment services that will deploy applications to EC2, Lambda, on-premise
- CodePipeline - Continuous Delivery to Model/Visualize/Automate steps for software release
- X-Ray - Used to debug/analyze serverless applications by showing traces
- Cloud9 - IDE Environment to develop code inside AWS consol
# Lộn xộn
- Elastic Beanstalk có thể tự động hóa deploy, tự tạo instance, ELB, VPC    
- Mặc định mỗi tài khoản AWS sẽ giới hạn 5IP Elastic
- Provisioned IOPS SSD at least 4GB in size
- AWS Import/Export : không thể export from Glacier
- Microsoft SQL: max 10GB per DB
- Key pair are used only for EC2 and CloudFront
- AWS Cloudformation sẽ rollback lại toàn bộ các service đã tạo, nếu có 1 service bị lỗi
- Federated Storage Engine: ???
- Oracle database: Oracle Data Pump
- AWS STS - giống access key + secret key nhưng mà có time expired đi kèm
- Với dịch vụ EC2, aws bắt đầu tính tiền khi EC2 được khởi tạo ở boot sequence, và kết thúc khi Instant shutdown
- Có thể acces với EC2, sử dụng SOAP protocol
- OpsWorks - Similar to elastic beanstalk, used to automate configuration of environments (convered in  Sysops Admin test)
- Data Pipeline - Way of moving data between different AWS services
- Glue - Used for ETL (extract, transform, load), glue is optimized to achieve this
- WAF - Web Application Firewall (7-layer firewall), monitoring application layer
- Shield - DDoS Mitigation
- GameLift - Service to help develop game services in AWS
- CDN - Edge Locations are not just read only, you can write to them, too
- Muốn share snapshot của Redshift cluster sang 1 region khác, thì cần BẬT `enable cross-Region snapshots.`
- General Purpose (SSD) Storage - This storage type is optimized for I/O-intensive transactional (OLTP) database workloads
- Provisioned IOPS SSD cũng support OLTP, performance cao hơn
- HDD st1 hợp cho log-processing, nhưng throughput từ 250-500
- AWS Trusted Advisor phân tích môi trường AWS của bạn và đưa ra khuyến nghị về phương pháp thực hành tốt nhất theo năm hạng, 1 kiểu như thư ký ảo
- ko sử dụng Redshift như 1 OLTP Database, nó chỉ nên dùng như OLAP Database
- Cloudwatch cannot remove EC2 instance from rotation but Route53 health check can do this
- With Amazon Kinesis Data Analytics for SQL Applications, you can process and analyze streaming data using standard SQL
- data in 8 KB chunks ==> NoSQL DB
- AWS Config - tool analyzes account resources and provides a detailed inventory of changes over time
- Khi design subnet, nhớ chú ý yếu tố nhân 2, vì để đảm bảo HA, thì mỗi AZ nên có 1 subnet
- Redshift có thể config độ ưu tiên cho mỗi  query  riêng biệt được?
- EFS does not support security groups.
- (Use an Amazon SNS topic to fan out the data to the SQS queue in addition to a Lambda function that records the data to an S3 bucket.
- Sử dụng AWS Organizations có thể set policy như IAM được, nhưng trong 1 số case, thao tác IAM tốn nhiều effort hơn
- AWS Batch is not to be confused for AWS Backup.
- AWS Batch plans, schedules, and executes your batch computing workloads using Amazon EC2 and Spot Instances and its not used to take backups. AWS Backup can perform backups.
- Nếu tạo Nat Gateway dùng chung cho 2 AZ, thì case AZ đang chạy Nat gateway down, sẽ làm cho AZ còn lại cũng ko có NatGateway dùng
- Aurora allows its read replicas to be easily promoted to the master and typically only has 100ms of replication lag 
- AWS Premium support: Basic, Developer, Business, Enterprise
- 3 level support của AWS : Enterprise, Business, Developer (ko có gói Free Tier)
- RDS supports SOAP only through HTTPS (not HTTP)
- Create the IAM roles with cross account access
- "Domain" refer to in Amazon SWF : A Collection of related workflows
- AWS CloudFormation : Json-formatted
- Document aws ghi rằng khi EC2 stop, thì data trên ec2 instance cũng mất đi. (chưa kiểm duyệt lại được, vì test thì thấy vẫn lưu bình thường???)
- Amazon's Redshift uses which block size for its columnar storage:  1024KB / 1 MB
- Với các app mobile cần authentication để truy cập vào db như DynamoDB => Nên sử dụng Web Identity Federation, cụ thể app sẽ call tới bên thứ 3 để xác thực user (Google, Facebook, Amazon...), để nhận token, sử dụng này để pass service AWS STS.
AWS STS sẽ cung cấp 1 temporary AWS access credential. Được quyền như IAM Role, accesss vào AWS Resource (trong case này là DynamoDB)
- Mỗi tài khoản AWS gồm:
    - AWS Account ID: such as `123456789012`. Dùng trong case ARN
    - Canonical User ID : such as `79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be`. Root user và IAM user sẽ cùng chung 1 `canonical user`. Được dùng trong case `cross-account access`.
- 1 Public subnet trong 1 VPC được định nghĩa là trong bảng định tuyến của nó, có ít nhất 1 route IGW
- Khi nào nên chọn Provisioned IOPS trên Standard RDS? 
    - Khi cần db OLTP
- Để lấy thông tin metadata của ec2, `curl http://169.254.169.254/latest/meta-data` (lưu ý 169.254.169.254 là địa chỉ IP cố định, ko phải thay đổi)
- AWS Direct Connect: 1Gbps - 10Gbps
- The maximum size of an Amazon EBS snapshot is 1TB 
- Provisioned IOPS sẽ được charge phí ngay cả khi ko dùng, mỗi tháng
- Storage size increments of at least 10% 
- Muốn bắn mail khi Instance được start/terminate khi chạy Auto Scaling thì phải config (nó ko tự gửi mail)
- Cần phải shutdown EC2 trước khi tạo snapshot 

- Route 53 không thể tạo hosted zone for a top-level domain 
- Không thể tạo IAM account giống nhau để login vào các AWS Account khác nhau
- RDS ko hỗ trợ giảm size db, nhưng với Dynamo DB (NOSQL) thì có support cả tăng và giảm 
- SQS ko support priority queue
- Security group sẽ merge các policy conflict lại với nhau (cái nào to hơn xài cái đó, ví dụ có 2 cái, 1 cái chỉ cho phép vào port 80 với IP xxx, và 1 cái cho phép vào port 80 với mọi IP, thì kết quả cuối sẽ là cho phép all) 
- AWS using SQS to store the message from mobile apps, and using AWS Mobile Push to send offers to mobile apps. 
- EC2 sẽ không bị terminate nếu tính năng "terminate protection" đang được enabled. Chế độ Auto Scaling, khi scale-in sẽ không thể terminate được instance
- AuTO Scaling support Manual scaling, và Dynamic Scaling 
- Trong một Region, thì việc user sử dụng AZ khác nhau ko giảm được latency. AZ mục đích chính để fault toleration hoặc HA 
- EBS Magnetic: 1 loại ổ đĩa HDD
- Amazon Redshift: 1 service phục vụ data warehouse,lưu data theo dạng COLUMNAR 
- Cross-account: account sau khi đăng nhập, có thể switch sang role khác của 1 tài khoản khác, mà không cần phải login/logout đăng nhập tài khoản đó. 
- Danh sách các subscriber của SNS 
    - Lambda 
    - SQS 
    - HTTP/S 
    - Email 
    - SMS 
- CloudFront được dùng để distribution origin cho các service sau:
    - S3
    - ELB 
    - MediaPackage Origins 
    - MediaStore Containers 
- CloudFront support cho cả static và dynamic content trên global
- AWS KMS : chỉ mã hóa với khóa đối xứng symetric key 
- Vì DynamoDB chỉ lưu được giới hạn data, nên có thể kết hợp với sử dụng S3 để lưu trữ, và DynamoDB sẽ lưu trữ vị trí trỏ tới S3 
- DynamoDB không hỗ trợ TRANSACTION giữa S3 và DynamoDB 
- S3 giới hạn độ dài của object identifiers
- Consolidated billing (Thanh toán tổng hợp): usecase 1 tài khoản master tạo ra organization và mời các tài khoản khác invite vào organization này. Khi đó tài khoản master là Paying account, sẽ thực hiện thanh toán toàn bộ chi phí của các tài khoản khác. Các tài khoản khác được invite, và không phải trả tiền là Linked Account 
- General Purpose SSD (gp2): 
    (Min: 1 GiB, Max: 16384 GiB)
    IOPS 300 / 3000
- Provisioned IOPS SSD (io1)
    (Min: 4 GiB, Max: 16384 GiB)
    (Min: 100 IOPS, Max: 64000 IOPS)



# FSx vs EFS
- Có vẻ FSX được thiết kế chuyên cho window server
- 1 số case sau nên dùng FSX
```Home directories for Windows desktops. See this AWS blog for details on using FSx for Windows with the Amazon WorkSpaces virtual desktop infrastructure service.
Windows line-of-business applications.
Web servers and content management systems built on Windows and deeply integrated with the Windows Server ecosystem.
Windows app dev environments, notably Visual Studio.
Media workflows.
Windows data analytics, such as Power BI, the SQL Server data platform, Sisense or other third-party applications.
```
- Fsx Có 2 loại: 
    - Cho window server. (dùng như kiểu share directory)
    - Cho Lustre
# Some topic
- https://aws.amazon.com/vi/premiumsupport/knowledge-center/migrate-nat-instance-gateway/
- https://acloud.guru/forums/aws-csa-2019/discussion/-LbnjIbr3jdqQdRSRa7s/VPC%20Endpoint%20Interface%20vs%20Gateway
- https://blog.treasuredata.com/blog/2016/02/10/whats-the-difference-between-aws-redshift-aurora/
- https://hevodata.com/blog/amazon-redshift-vs-aurora/
- https://dev.to/garyker/aws-classic-load-balancer-vs-application-load-balancer-12m0
- https://medium.com/awesome-cloud/aws-difference-between-ebs-and-instance-store-f030c4407387
- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-monitoring-using-cloudwatch.html
- https://docs.aws.amazon.com/vpc/latest/userguide/egress-only-internet-gateway.html
