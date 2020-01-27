# 1. AWS ElastiCache 
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

ElastiCache có kết hợp với DNS của Amazon, để khi node mới thay thế node lỗi, thì node mới sẽ có IP, policy của node cũ luôn, ựng dụng của developer sẽ được chạy thông suốt, mà developer không phải config lại cái gì. Lưu ý: việc sao chép data giữa các cluster là không đồng bộ và sẽ mất 1 khoảng thời gian delay.

## 1.4 ElastiCache backup và recovery data thế nào? 
Với Memcached thì không hỗ trợ tính năng này, khi tạo mới 1 Memcached cluster, thì sẽ luôn là empty data.       
Với Redis, ElastiCache cung cấp cửa sổ để developer cấu hình lịch định kỳ để tạo các bản snapshot, các file backup này được lưu trữ trong S3 (1 service lưu trữ của Amazon). Các bản snapshots thực hiện thủ công manual, sẽ được lưu trữ mãi mãi, cho tới khi bạn xóa nó.

## 1.5 Access Control
Về việc cấp quyền access, thì ElastiCache dựa theo NETWORK. Nghĩa là nó dựa vào địa chỉ IP, subnetmask để xây dựng lên các chính sách network, việc access sẽ dựa vào security groups này.      
Lưu ý: các node không bao giờ được access từ ngoài internet, hoặc từ EC2 bên ngoài VPC chạy ElastiCache. Có thể hạn chế xâm nhập vào bằng cách cấu hình trong ACL (Acess List) .        
Về việc manage, sử dụng service IAM, AWS Identity của Amazon để định nghĩa các chính sách cho các AWS User.

# 2. Amazon Route 53
![Route53](https://blog.outsource.com/wp-content/uploads/2018/10/getting-started-on-aws-74-638.jpg)

Là một dịch vụ tên miền DNS     
## 2.1 chức năng chính
- Register domain names
- Route internet traffic to the resources for your domain
- Check the health of your resources

## 2.2 Tính năng
- Kết nối hiệu quả với EC2, S3, ELB, Cloudfront
- Using Traffic Flow to Route DNS Traffic: Có thể sử dụng để redirect traffic, định tuyến enduser tới endpoint tốt nhất dựa theo: geoproximity, latency, health, and other considerations
- DNS failover: Route 53 tự động phát hiện sự cố của website và redirect truy cập user tới 1 locations khác. Khi bật tính năng này, thì
Route 53 sẽ thành 1 helth checking agent, để giám sát tính "availabale" của các endpoint
- Private DNS for Amazon VPC (A private hosted zone) dùng để làm DNS private cho các service trong cùng 1 VPC.  Ví dụ có thể tạo ra các record A, AAAA như db.example.com để DNS cho các query domain đến từ nội bộ VPC. Kết quả được trả về trước khi DNS ra ngoài global
![Create hosted zone](https://blog.andrewray.me/content/images/2017/09/hosted-zones.jpg)
- Domain Name Registration: trả tiền để thuê tên miền

## 2.3 Các Routing policy:
- Simple routing policy: dùng cho 1 resource, định tuyến domain tới server 
- Failover routing policy: dùng để định tuyến traffic khi có server bị deactive, nó sẽ redirect tới server active
- Geolocation routing policy: định tuyến theo vị trí địa lý
- Geoproximity routing policy : định tuyến theo vị trí tài nguyên của mình, tùy ý
- Latency routing policy: được sử dụng với Multi Region, dùng để định tuyến tới region có đệ trễ thấp nhất
- Multivalue answer routing policy: định tuyến random, kết quả trả về là 1 trong 8 record của DNS
- Weighted routing policy: định tuyến truy cập tới các server theo hệ số khác nhau mà mình config


## 2.4 Các API mà Route 53 cung cấp
- CreateHostedZone: tạo hosted zone chứa DNS data, sau khi tạo Hosted zone sẽ nhận được 4 name server
- GetHostedZone: lấy thông tin của Hosted Zone
- DeleteHostedZone
- ChangeResourceRecordSets
- ListResourceRecordSets
- CheckAvailability
- RegisterDomain

# 3. AWS Lambda
AWS Lambda nằm trong category "Compute" của danh sách các service mà Amazon web service cung cấp. 

Sự khác biệt giữa EC2 và Lambda là gì? 
- Lambda là serverless (không có các tài nguyên như RAM, CPU, Disk...), còn EC2 thì ngược lại, nó là server. 

Lambda có công dụng gì? 
- Lambda chỉ để chạy các đoạn code đã được developer lập trình. Nghĩa là sẽ không thể cài đặt được software, library, 
tool của bên thứ 3 như vẫn hay thường cài trên 1 server truyền thống. 
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

# Chưa có time tổng hợp
- ELB chỉ chạy được trong 1 hoạc nhiều AZ? tức là khác region thì ko chạy được?
Có thể chạy khác Region được, nhưng cần phải có Route 53
- RDS hỗ trợ lưu data tối đa là 35 ngày
- Mặc định mỗi tài khoản AWS sẽ giới hạn 5IP Elastic
- EBS : the data set?
- Dynamic DB: 10 000 beyond
- Provisioned IOPS SSD at least 4GB in size
- AWS Import/Export : không thể expỏt from Glacier
- Không thể di chuyển Reserved instance từ 1 region tới another
- 1 IOPS - 256KB IO
- Microsoft SQL: max 10GB per DB
- Key pair are used only for EC2 and CloudFront
- Khi nhìn thấy keyword non-production workloads cái mà có thể interupted, immediately => chọn spot instances
- Elastic Map Reduce
- AWS Cloudformation sẽ rollback lại toàn bộ các service đã tạo, nếu có 1 service bị lỗi
Instance type khác nhau thì sẽ có số ENIs có thể đính vào khác nhau
- Amazon Web servicé , cung cấp các cơ chế định danh hỗ trợ: Facebook, Google, Amazon
Federated Storage Engine: ???
- Oracle database: Oracle Data Pump
- Redshift
- AWS STS
- Sau khi chạy Start VPC Wizard, thì không thể có lựa chọn nào nữa?
- VPC with a Public Subnet Only and Hardware VPN Access
AWS Security Token Service
PIOPS la gi?
- Với dịch vụ EC2, aws bắt đầu tính tiền khi EC2 được khởi tạo ở boot sequence, và kết thúc khi Instant shutdown
- Có thể acces với EC2, sử dụng SOAP protocol
- Application vs Classic Load Balancer????
Direct Connect

# Amazon EC2

# EC2 
## EC2 Enhanced Networking 
- Đó là một cách để đảm bảo sử dụng CPU thấp hơn, và hiệu năng I/O cao hơn
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
- Pass script chạy sau khi EC2 instance launched (ví dụ như script sau khi chạy thì update OS, run shell script...)

## EC2 - Placement Groups 
- Là một tính năng cho phép các EC2 liên quan có thể kết nối với nhau với băng thông cao, độ trễ thấp, trong cùng 1 AZ
- Yêu cầu cùng 1 AZ
- Có thể sử dụng Enhanced networking instances trong Placement groups

## EC2 - Bastion Host 
- 1 Computer được cấu hình đặc biệt, thuộc miền external/ public (DMZ) hoặc bên ngoài firewall, hoạt động như một server trung gian, cho phép bạn connect vào các Instance nằm trong Private Subnet
- Trường hợp Instance bị terminated, nhưng Auto Scaling Group đang launches, thì Elastic IP sẽ được đính lên cho instances mới


## EC2 - Spot instances
- Đấu thầu để được chạy instances (các tài nguyên mà AWS đang dư thừa), giá rẻ hơn Instances on-demaind rất nhiều. Tuy nhiên khi nào có người khác trả giá cao hơn giá mình thầu, thì instance đó sẽ bị terminated
- Spot instance không đảm bảo luôn luôn khả dụng, nhưng giá rất rẻ

## EC2 - Rerserved Instances 
- Là Instances on-demand, nhưng có thuê bao, trả trước sẽ có giá rẻ hơn. Ví dụ đảm bảo dùng trong 12 tháng.
- You can NOT migrate RI instances between regions
- They can be used to launch AS Group instances or standalone ones

## EC2 - IAM Roles
- Gán quyền để application access read/write S3, SQS, DynamoDB, SNS...
- Default IAM Roles cho phép EC2 instances access vào các service khác 
- You can add the IAM role while the instance is running 

## EC2 - ENIs
- Network interfaces được tọa bởi CLI sẽ KHÔNG được tự động terminated khi EC2 instance terminates.

## EC2 - Instance Immediate Termination 
- AWS khuyến cáo sau khi launch EC2 cần check trạng thái của EC2 để chắc chắn là nó là "running", và không phải là "terminated"
- Một vài lỗi khiến EC2 bị terminate khi launch:
    - AMI thiếu 1 số part
    - Limit volume EBS
    - Bản snapshot EBS bị lỗi
- Để tìm lỗi termination:
    - From Console: Go to Instances (select the instance) -> Description tab -> State Transition reason
    - From CLI use the "describe-instance command

## EC2 Troubleshooting - Insufficient Capacity Error
- Lỗi: Insufficient Instance Capacity
- If you get an InsufficientInstanceCapacity error when you try to launch an instance or start a stopped instance:
    - The reason is: AWS does not currently have enough available capacity to service your request
        - To solve the problem try one or more of the following
            - Wait a few minutes and then submit your request again
            - Submit a new request with a reduced number of instances
            - (If launching an Instance) Submit a new request without specifying an AZ
            - (If launching an Instance) Submit a new request using a different instance type (which you can resize at a later stage)
            - Try purchasing Reserved Instances

# Elastic Network Interface
- Là card mạng ảo, được đính vào EC2 (vd: eth0, eth1...)
- Khi EC2 bị terminated => Nếu ENI tạo bằng console thì cũng terminate theo, nếu tạo bằng command line thì ko bị terminated
- Có thể được cấu hình khi: instance running, stopped, launched
- 1 ENI chỉ được cho 1 Insntace, nhưng 1 instance có thể attached nhiều ENI
- Subnet có thể khác nhau nhưng phải chung VPC, chung AZ

# RDS
- Service cung cấp hệ quản trị SQL: MySQL, PostgreSQL...
- HA luôn được implies Multi-AZ
- Read Replicas có thể được sử dụng để scale READ performance, tuy nhiên
    - Không thể với WRITE
    - Có sự bất đồng bộ giữa các node
- AWS quản lý fully managed service, tức là dev ko thể can thiệp được vào OS, instance chạy RDS => chỉ access được vào RDS enginer
- Primary và standby có thể khác AZs 
- Không nên sử dụng IP address làm point để kết nối, mà nên sử dụng emdpoint (endpoint kiểu domain dài dài loằng ngoằng)
- Có thể sử dụng CloudWatch Alarm ddeer monitor metric, và alarm
- CloudTrail để logs all AWS RDS API
- Có thể read replica (được với MySQL, MariaDB, PostgreSQL (MyMaPo) )
- Quá trình scale, hay chuyển giao primary-standby sẽ mất vài phút
- Khi chạy Multi-AZ RDS thì chế độ backups và snapshots sẽ được tự động chạy 
- Không thể set standby ở region khác 
- Không thể read/write tới Standby RDS DB instance
- Tất cả RDS db engines đều có thể có dung lượng lưu trữ lên > 6GB, trừ MS SQL
- MS SQL DB engine can have storage capacity up to 4TB
- Không thể giảm size của RDS sau khi chạy, chỉ có thể tăng
- Amazon RDS Provisioned IOPS Storage được dùng để tăng performance (ứng dụng nào yêu cầu I/O cao, thì nên dùng )
- Có thể test DB instance against trước khi upgrade version. Step:
    - Tạo 1 bản DB snapshot mới cho DB đang chạy
    - Restore bản snapshot sang DB instance mới
    - Khởi tạo, upgrade version mới trên DB instance mới
- Mỗi DB instance có 1 cửa sổ maintance weekly 
- Việc upgrade version RDS có 2 loại
    - Major version Upgrades
    - Minor version Upgrades
- Với "major", AWS sẽ không tự động, phải làm bằng tay thủ công. Không thể revert về version trước đó. Nếu muốn restore thì trước khi upgrade nên tạo 1 instance mới và chứa data snapshot đó
- Không thể restore 1 bản snapshot tới 1 instance đã tồn tại DB (cần tạo mới, và restore vô cái mới)

- Không thể thay đổi Storage type (magnetic, Provisioned IOPS, General purpose) trong suốt quá trình restore thực thi
- Nếu set retention period = 0, tương đương tắt chế độ automatic backups. 
- If you set retention period to zero, automatic backups are disabled
- Khi bạn restore a DB instance, chỉ có các tham số mặc định và Security groups đã được liên kết mới có thể restore
- Sau lưu tự động hiện tại chỉ support InnoDB , MySQL (ko support cho MyISAM)
- Tính năng khôi phục theo thời gian Point-In-Time chỉ được hỗ trợ cho MySQL, InnoDB
- InnoDB có vẻ là chiến lược của AWS, ko thấy support khá nhiều ưu ái

# S3 
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

- Nếu bucket của bạn có lượng truy cập dưới 100 PUT/LIST/DELETE cho mỗi giây, hoặc dưới 800 GET request mỗi giây, thì ko cần phải cấu hình gì cho S3 để nâng performance cả
- Ngược lại: 
    - Random prefix để chúng được lưu vào các phân vùng khác nhau
    - Sử dụng CloudFront để phân phối tải tới S3
- Versioning is enabled

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

- IAM users/groups/roles không thể gán quyền cho Object, ACL
- IAM users/groups/roles không thể 
- AWS sẽ không replicate dữ liệu ra ngoài region, nó chỉ sao chép trong nhiều facilities (AZ)
- Mặc định, tất cả objects sẽ gán quyền private, và chỉ có owner mới có thể access
- Để chia sẻ object bạn có 2 cách
    - Set quyền object public 
    - Tạo pre-signed URL 

- bucket 
    - là container
    - global name, unique across all AWS accounts
- object
    - 0 bytes - 5 TB
    - Dung lượng lớn nhất cho 1 PUT request upload là 5GB (nếu dung lượng lớn hơn 100MB, cân nhắc nên sử dụng Multipart Upload)
    - key (name of object) + Data + metadata (describe, object size, MD5 digest, other...) + version ID
- Data tự động được replicated trong 1 region


- Use case:
    - backup, storage on-premises data
    - content, media, and software storage and distribution
    - bigdata
    - static website hosting
    - Cloud-native mobile and internet application hosting
- Security
    - ACL
    - BucketPolicies
        - IP address range
        - AWS account
        - Objects with a specific prefix
    - Encryption


- Có thể tích hợp với các service khác của AWS:
    - Như SNS, SQS, Lamda
    
# VPC
## 1. Security
### Security groups vs Network ACLs
|  Security groups  |  Network ACLs | 
|---|---|
|  instance level | subnet level  | 
|  stateful | stateless  |  

- Security groups STATEFUL: responses to allowed inbound traffic are allowed to flow outbound regardless of outbound rules, and vice versa. (tức nếu đồng ý cho phép chiều đi vào, thì chiều đi ra cũng sẽ được đồng ý, ngược lại)
- Network ACL STATELESS: eg: if you enable inbound SSH on port 22 from the specific IP address, you would need to add a Outbound rule for the response as well (Nếu có rule đồng ý cho kết nối tới port 22 đi vào, thì cũng phải có rule cho phép đi ra)

### 1.1 Security groups
- Có thể sử dụng Security Group names như 1 khai báo "source" hoặc "destination" cho 1 Security Group khác
- Chỉ có rule allow (không thể khai báo rule deny, nếu không khai báo allow thì mặc định traffic là deny)
- Default là deny tất cả traffic inbound, và allow tất cả traffic outbound
- (ko hiểu) Remember Private subnet DB instance will want to Access websites on the internet (HTTP or HTTPs)
- Instances mà có public subnet thì không cần thông qua NAT instance nữa (hiển nhiên)


## 2. VPC peering 
- Dùng để kết nối giữa các VPCs. Ví dụ: kết nối các EC2 ở các Region khác nhau
- Hạn chế:
    - không thể định tuyến gói tin từ VPC B tới VPC C thông qua VPC A 
    - không thể khởi tạo, nếu như có sự trùng lặp, conflict CIDR blocks giữa các VPC (ví dụ: cùng chung dải mảng 10.0.0.0/16)
    - giữa 2 VPC, tại cùng 1 time, chỉ có thể có duy nhất 1 VPC peering

## 3. AWS Direct Connect
- AWS cung cấp 1 số địa điểm (office vật lý) để khách hàng có thể tới trực tiếp cắm dây mạng vào để kết nối tới hệ thống của AWS. => giảm chi phí truyền tải băng thông trên internet . Giải quyết:
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
- Không thể tạo 1 block CIDR mới mà trùng với cũ (hiển nhiên)


# ELB
- Phân phối traffic cho các EC2 ở nhiều AZ 
- Sticky sessions 
- X-Forwarded-For:
    - get client IP address
    - get previous Request IP Address
    - get Load Balancer IP Address

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

## ELB - Proxy Protocol
- Trước khi bật tính năng Proxy Protocal thì cần chắc chắn rằng trước Load Balancer chưa có proxy server

## ELB - Sticky sessions
- Trường hợp BE instance bị chết, ELB sẽ định tuyến traffic tới 1 instance mới, khỏe mạnh, và sticky session trên instance mới. (kể cả khi instance cũ đã khỏe lại)
- For ELB, duration based, cookie stickiness:


## Connection Draining 
- Is disabled by default
- Khi có Instance không thể checking được healthy, thì ELB sẽ không route traffic tới nữa?
- Default, wait 300 seconds

- Kịch bản để có HA tốt
    - VPC (với config Sec groups và N ACLs đúng) with IGW configured attached
    - tối thiểu 2 AZs trong cùng 1 region
    - Public subnet(s) in each AZ, ELB defined on one of them to enable it to serve the AZ
    - Private subnet for the data base tier (to protect it)
    - Multi-AZ RDS or AWS managed DB engine
    - Auto scaling defined in both AZs and configured to work with the ELB and EC2 instances. 
    
- Nếu bạn cần có ELB trong giải pháp HA, bạn không cần phải cấu hình 2 ELB riêng biệt => AWS sẽ làm cho bạn

## Session Affinity and Application Performance
- If the ELB is configured with session affinity (sticky sessions), it will continue to route the requests from the same clients to the same backend EC2 instances disregarding:
- Can be used to host multiple domains on a single server/IP when it is not feasible to group them all on one certificate
- The big advantage of SNI is, it will allow the server (or Load balancer) to present many certificates on the same server IP address and TCP port nuber, which means multiple secure (HTTPS) websites can be served from the same server IP address, and each of these websites can have its own Certificate (They do not have to have the same certificate)

## SNI and ELB
- Server Name Indication (SNI) là một phần mở rộng của giao thức mạng máy tính TLS . Nó cho phép một máy chủ có thể sử dụng nhiều chứng chỉ SSL cho nhiều tên miền trên cùng một địa chỉ IP mạng WAN. Nó giống như việc sử dụng https cho nhiều tên miền cùng sử dụng chung một địa chỉ IP để tiết kiệm
- Elastic Load Balancing không hỗ trợ Server Name Indication (SNI) => cần tìm giải pháp
- X-Forwarded-For is supported with HTTP/HTTPS listeners only
- Proxy protocol is supported with TCP/SSL listeners only

## ELB-Pre-Warming
ELB Scaling:
- Thời gian để ELB phát hiện được việc tăng traffic là khoảng 1-7p
- ELB không được thiết kế để queue requests
- Trả về lỗi 503, nếu ELB không thể handle được request
- Nếu traffic có thể tăng quá nhanh, hơn 50%, thì cần contact AWS để pre-warm
- Khi ELB scales, nó sẽ update DNS record với danh sách IP mới
- Để chắc chắn clients đang có sự gia tăng về capacity, ELB sẽ gửi TTL tới DNS Record mỗi 60s
