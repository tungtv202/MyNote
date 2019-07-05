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
