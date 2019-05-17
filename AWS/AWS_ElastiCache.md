# AWS ElastiCache - dịch vụ cung cấp Redis,NameCached trên AWS
### 1. Amazon ElastiCache là gì?
Nó là 1 web service của Amazon Cloud, là 1 service giống như rất nhiều service khác, ví dụ EC2, S3, VPC… mục đích cho developer có thể kết hợp các service lại với nhau tạo thành các combo, phục vụ use case của developer trong việc phát triển ứng dụng. ElastiCache chính là dịch vụ cung cấp Memcached, Redis. Thay vì bây giờ phải tạo các máy ảo EC2, xong sau đó cài đặt Memcached hoặc Redis, rồi cấu hình, rồi config nhiều thứ khác nữa, thì ElastiCache cho phép developer config, setup, manage nhanh hơn, bằng việc click click trên giao diện web => tập trung thời gian cho việc phát triển ứng dụng, đỡ phải care nhiều về hạ tầng.

### 2. Lý do ra đời ElastiCache?
ElastiCache cung cấp service về Redis, Memcached. Vậy lý do ra đời Redis, Memcached là gì?

2 thằng này rất là nổi tiếng, ai developer chắc cũng biết. Redis, Memcached là 2 platform (mình không biết là nên dùng từ platform, hay tool, hay enviroment nữa TT ) dùng để lưu trữ data trên bộ nhớ trong (RAM). Lý do ra đời 2 thằng này, đó là vì data được lưu trữ trên RAM, thì tốc độ write, read rất là nhanh, nhanh hơn rất nhiều so với việc query từ database (MySQL, SQL Server, PostgresSQL…) cái mà lưu trữ trên ổ cứng (disk). Tốc độ read data nhanh thì người dùng sẽ có những trải nghiệm tốt => ứng dụng của bạn sẽ thành công hơn.

Ví dụ được nêu trong sách: vào năm 2007, cuộc kiểm tra của nhà bán lẻ Amazon.com đã chỉ ra rằng, cứ giảm thời gian phản hồi của website xuống mỗi 100ms, thì doanh thu bán hàng lại tăng lên 1%. Nói chung là 2 thằng này ra đời để cache các data mà thường xuyên được sử dụng.

Theo đúng kịch bản thì ứng dụng server sẽ kiểm tra trong cache đầu tiên, để tìm dữ liệu mà nó cần, nếu không tồn tại thì nó sẽ truy vấn tới các node database.

### 3. Sự khác biệt giữa Memcached với Redis
3 khác biệt cơ bản

- Memcached thì cung cấp dữ liệu dạng key/value đơn giản hơn. Đơn giản chỉ là chuỗi string hoặc binary data. Trong khi Redis thì phức tạp hơn, nó còn có set, lists, zset, hash… dữ liệu có nhiều loại hơn, có tổ chức hơn, có sort, có rank.
- Memcached thì không hỗ trợ persis data (dữ liệu không được save, không được snapshoot, 1 khi đã mất là mất). Trong khi Redis thì có cơ chế backup, có cơ chế snapshoot và lưu vào disk, có thể tạo ra 1 cluster Redis mới bằng việc khởi tạo từ bản snapshoot được lưu.
- Memcached thì có thể dựng nhiều node (trong sách thấy ghi là tối đa 20 node) để tạo thành 1 cluster. Còn Redis thì mỗi 1 cluster là 1 single node. Nhưng nhiều cluster thì có thể group lại thành 1 nhóm (Redis replication group).

### 4. Scaling
ElasticCache cho phép việc scaling theo chiều ngang.    
Bị hạn chế scaling theo chiều dọc.  

### 5. Khi có node lỗi, ElastiCache làm gì?     
Nó tự phát hiện ra lỗi, khi có lỗi, nó sẽ thay thế và tự thêm mới 1 cluster. Trong suốt thời gian này, truy vấn sẽ được gửi tới database => database sẽ bị tăng lưu lượng.  
Riêng với ElastiCache chạy Redis, có 1 tính năng của Amazon là Multi-AZ replication group, nếu tính năng này được bật, thì:     
- Khi primary node bị lỗi => read replica sẽ được tự động đẩy lên làm primary
- Node lỗi => sẽ tự động được thay thế bởi 1 node mới. Vậy primary node là gì? Read replica node là gì? Primary node đó là node chạy Redis với đủ quyền read lẫn write, còn read replica thì chỉ có quyền read, 1 con primary có thể có tới 5 con read replica, mục đích để san sẻ tải. 
![EC](https://images.viblo.asia/d6e4b83d-c326-4ad2-a2a6-51473680d636.jpg)

ElastiCache có kết hợp với DNS của Amazon, để khi node mới thay thế node lỗi, thì node mới sẽ có IP, policy của node cũ luôn, ựng dụng của developer sẽ được chạy thông suốt, mà developer không phải config lại cái gì. Lưu ý: việc sao chép data giữa các cluster là không đồng bộ và sẽ mất 1 khoảng thời gian delay.

### 6. ElastiCache backup và recovery data thế nào? 
Với Memcached thì không hỗ trợ tính năng này, khi tạo mới 1 Memcached cluster, thì sẽ luôn là empty data.       
Với Redis, ElastiCache cung cấp cửa sổ để developer cấu hình lịch định kỳ để tạo các bản snapshot, các file backup này được lưu trữ trong S3 (1 service lưu trữ của Amazon). Các bản snapshots thực hiện thủ công manual, sẽ được lưu trữ mãi mãi, cho tới khi bạn xóa nó.

### 7. Access Control
Về việc cấp quyền access, thì ElastiCache dựa theo NETWORK. Nghĩa là nó dựa vào địa chỉ IP, subnetmask để xây dựng lên các chính sách network, việc access sẽ dựa vào security groups này.      
Lưu ý: các node không bao giờ được access từ ngoài internet, hoặc từ EC2 bên ngoài VPC chạy ElastiCache. Có thể hạn chế xâm nhập vào bằng cách cấu hình trong ACL (Acess List) .        
Về việc manage, sử dụng service IAM, AWS Identity của Amazon để định nghĩa các chính sách cho các AWS User.