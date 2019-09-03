- Với các app mobile cần authentication để truy cập vào db như DynamoDB.
Nên sử dụng Web Identity Federation, cụ thể app sẽ call tới bên thứ 3 để xác thực user (Google, Facebook, Amazon...), để nhận token, sử dụng này để pass service AWS STS.
AWS STS sẽ cung cấp 1 temporary AWS access credential. Được quyền như IAM Role, accesss vào AWS Resource (trong case này là DynamoDB)

- Mỗi tài khoản AWS gồm: AWS Account ID + Canonical User ID 

By definition a public subnet within a VPC is one that: in it's routing table it has at least one route that uses an Internet Gateway IGW

Using Amazon CloudWatch's Free Tier, what is the frequency of metric updates which you receive? - 5 minutes

When should I choose Provisioned IOPS over Standard RDS storage?
- If you use production online transaction processing OLTP workloads

DB Subnet Group

DB instance class maximum size: 6TB

EC2 when charge? 
Billing commences when Amazon EC2 initiates the boot sequence of an AMI instance and billing ends when the instance shuts down

AWS Premium SUpport?
- Basic, Developer, Business, Enterprise

RDS supports SOAP only through HTTPS (not HTTP)

Create the IAM roles with cross account access

"Domain" refer to in Amazon SWF 
- A Collection of related workflows

AWS CloudFormation : Json-formatted 

When an EC2 EBS-backed instance is stopped,
Data will be deleted and will no longer be accessible

Amazon's Redshift uses which block size for its columnar storage?
- 1024KB / 1 MB

Kinesis la gi

To find out both private IP and Public IP  of EC2
- Retrieve the instance Metadata from http://169.254.169.254/latest/meta-Data

AWS Direct Connect:
- 1Gbps - 10Gbps

Reserved Instance available for Multi-AZ deployment
- Yes for all instance types 

Are u able to integrate a multi-factor token service with the AWS Platform?
- Yes, using the AWS multi-factor token devices to authenticate users on  the AWS Platform

The maximum size of an Amazon EBS snapshot is 1TB 

Provisioned IOPS sẽ được charge phí ngay cả khi ko dùng, mỗi tháng

Storage size increments of at least 10% 

Muốn bắn mail khi Instance được start/terminate khi chạy Auto Scaling thì phải config (nó ko tự gửi mail)

Để chạy t2, sử dụng HVM AMI 

Cần phải shutdown EC2 trước khi tạo snapshot 

Route 53 không thể tạo hosted zone for a top-level domain 

It is not possible to have the same IAM account login URL for separate AWS accounts 

RDS ko hỗ trợ giảm size db, nhưng với Dynamo DB (NOSQL) thì có support cả tăng và giảm 

SQS có thể set độ ưu tiên được ko?
Không, chỉ có cách thủ công là tạo ra nhiều hàng đợi, và xử lý logic độ ưu tiên mỗi hàng đợi trong code. 

Security group sẽ merge các policy conflict lại với nhau (cái nào to hơn xài cái đó, ví dụ có 2 cái, 1 cái chỉ cho phép vào port 80 với IP xxx, và 1 cái cho phép vào port 80 với mọi IP, thì kết quả cuối sẽ là cho phép all) 

AWS using SQS to store the message from mobile apps, and using AWS Mobile Push to send offers to mobile apps. 

EC2 sẽ không bị terminate nếu tính năng "terminate protection" đang được enabled. Chế độ Auto Scaling, khi scale-in sẽ không thể terminate được instance

Elastic IP và Public IP: Elastic IP thì nó được assign dính luôn vào Instance, còn Public IP thì sau mỗi lần bật tắt, thì có thể assign 1 IP public mới 

Để kết nối tới EC2, sử dụng SSH key, window passwords và Security Groups sẽ kiểm soát việc access này. 
Không có 1 cách nào để IAM system can thiệp được vào ở tầng operating system

AuTO Scaling support Manual scaling, và Dynamic Scaling 

Trong một Region, thì việc user sử dụng AZ khác nhau ko giảm được latency.
AZ mục đích chính để fault toleration hoặc HA 

3 level support của AWS : Enterprise, Business, Developer (ko có gói Free Tier)

EBS Magnetic: 1 loại ổ đĩa HDD

Amazon Redshift: 1 service phục vụ data warehouse, bình thường các loại SQL là lưu data theo row. Với Redshift thì lưu data theo dạng COLUMNAR 
(dễ nén data, và khi xử lý với data lớn cho performance cao hơn) 

Cross-account: account sau khi đăng nhập, có thể switch sang role khác của 1 tài khoản khác, mà không cần phải login/logout đăng nhập tài khoản đó. 

Danh sách các subscriber của SNS 
- Lambda 
- SQS 
- HTTP/S 
- Email 
- SMS 

CloudFront được dùng để distribution origin cho các service sau:
- S3
- ELB 
- MediaPackage Origins 
- MediaStore Containers 

AWS KMS 
Chỉ mã hóa với khóa đối xứng symetric key 

Vì DynamoDB chỉ lưu được giới hạn data, nên có thể kết hợp với sử dụng S3 để lưu trữ, và DynamoDB sẽ lưu trữ vị trí trỏ tới S3 
(You can also use the object metadata support in Amazon S3 to provide a link back to the parent item in DynamoDB)
- DynamoDB không hỗ trợ TRANSACTION giữa S3 và DynamoDB 


S3 giới hạn độ dài của object identifiers

Consolidated billing (Thanh toán tổng hợp): usecase 1 tài khoản master tạo ra organization và mời các tài khoản khác invite vào organization này. 
Khi đó tài khoản master là Paying account, sẽ thực hiện thanh toán toàn bộ chi phí của các tài khoản khác. 
Các tài khoản khác được invite, và không phải trả tiền là Linked Account 


- General Purpose SSD (gp2): 
    (Min: 1 GiB, Max: 16384 GiB)
    IOPS 300 / 3000
- Provisioned IOPS SSD (io1)
    (Min: 4 GiB, Max: 16384 GiB)
    (Min: 100 IOPS, Max: 64000 IOPS)
