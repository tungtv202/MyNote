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
