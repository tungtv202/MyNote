
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
