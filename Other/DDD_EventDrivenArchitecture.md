---
title: Domain Driver Design & Event Driven Architecture
date: 2020-01-26 18:00:26
updated: 2020-01-26 18:00:26
tags:
    - ddd
    - domain driver design
category: 
    - other
---
# Domain Driver Design và Event Driven Architecture
- Đặt đơn hàng trong giờ cao điểm, cái khách hàng quan tâm là đặt đúng hàng họ cần, đúng số lượng, và có thông báo thành công => quá trình xử lý lúc đặt giờ cao điểm nó `khác với quá trình xử lý đơn hàng cho người vận hành tại thời điểm sau đó` => thiết kế
- Hệ thống chạy nhanh không bằng hệ thống chạy ổn định 
- Ví dụ: nói về đơn hàng, sẽ có order và order item. Database sẽ có 2 table, order và order item, nhưng sẽ chỉ có 1 object Order. Vì khi đã nói tới đơn hàng, thì sẽ có order và order item, không thể có 1 đơn hàng, mà đơn hàng đó không có sản phẩm, và không thể nói về sản phẩm đơn hàng, mà không biết đơn hàng nào.  
- Giả sử cần lấy 2 field thông tin, thì dùng 2 query khác nhau (đã được global trong hệ thống), rồi dùng code tổng hợp lại, còn hơn là viết 1 query mới lấy ra 2 field chỉ để giải quyết 1 nhu cầu.
- `Model` không phải là `Table`. 
    - `Table` thiết kế để lưu trữ ghi nhanh, đọc nhanh
    - `Model` phản ánh tính chất logic nghiệp vụ của hệ thống
- **Aggregate** 
    - là một nhóm các đối tượng dữ liệu được đối xử như 1 thể thống nhất trong hệ thống. 
        - VD: order và order item  phải coi như là 2 thành phần nhất quán của đối tượng aggregate order, định danh trong hệ thống là order id
    - đảm báo cách nhìn thống nhất trong toàn bộ hệ thống
    - khi nói đến 1 aggregate phải nói tới 1 đối tượng dữ liệu ` toàn vẹn, đầy đủ `
    - không tồn tại các nghiệp vụ riêng biệt với từng thành phần của 1 aggregate
    - tất cả các logic từ data access tới service đều phải xoanh quanh các aggregate
    - chọn lựa phạm vi aggregate `vừa đủ`
    - phạm vi aggregate quá lớn sẽ dẫn đến performance không tốt
    - phạm vi aggregate quá bé sẽ dẫn tới logic bị phân mảnh và khó quản lý
    - đảm báo các thành phần của 1 aggregate luôn nhất quán  
    - sử dụng pattern về data access thống nhất
        - Repository Pattern
        - ORM
    - Cấu trúc resource API tương ứng với các aggregate
- **Don't repeat Yourself:**
    - Không nhầm lẫn Aggregate và các DTO  (DTO là nhu cầu làm việc gì đó với 1 cục dự liệu nào đó? và code để Data Access cho tầng dữ liệu đó? @@)
    - Không design API dựa theo nhu cầu hiển thị
    - Không xây dựng data access theo từng chức năng


#### Mô hình kiến trúc
![MoHinhKienTruc](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/ddd/MoHinhKienTruc.JPG)


#### Infrastructure Layer
- Đảm nhiệm vai trò làm việc với các thành phân bên dưới như DB,
    Message Queue, File...
- Phần lớn logic của hệ thống là logic nghiệp vụ
- Không để logic của phần infrastructure làm giảm tốc độ phát triển
    của nghiệp vụ
- Phải có khả năng tái sử dụng cao
- Phai nhất quán trong toàn bộ cấu trúc hệ thống
- **Pattern:**
    - Repository Pattern
    - Observer Pattern
    - ORM Pattern

#### Mức độ tái sử dụng
![Layer](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/java/ddd/layer.JPG)
- Các layer càng cao thì càng được sử dụng nhiều.
- Các layer càng bên dưới thì càng phải tái sử dụng cao
- Tránh thiết kế để độ phức tạp là ngang nhau giữa tất cả các layer.

#### Đảm bảo thứ tự của message
- Đảm bảo thứ tự ghi dữ liệu
- Đảm bảo thứ tự gửi event
- Đảm bảo thứ tứ nhận event

#### - Solution đảm bảo thứ tự ghi       
- **Solution 1:** lock theo key range, sử dụng transaction mode lock
serializable
Ví dụ: lock theo key là id order    
- **Solution 2:** sử dụng hai resources:    
        R1: snapshot của object     
        R2: event log   
        Lock lệnh update trên R1 và append vào R2   
- **Solution 3:** nếu lưu event trên table, thì sử dụng bộ cặp primary key
của event:          
Aggregate Id – Version      
Các event cùng version sẽ bị đụng độ khi insert.

#### - Solution đảm bảo thứ tự gửi
- Không áp dụng đồng thời ghi DB và gửi event vì không có transaction.
- Phải gửi log các event trước khi gửi đi
- Gộp nhóm các event theo id của aggregate phát event. Lưu trữ event với
    cặp key: aggregateId – version
- Load các event cần gửi theo aggregate id, và gửi tuần tự theo version
- Dừng gửi ngay khi gặp event lỗi
- Xử lý sự cố -> Load lại theo aggregateId và gửi tiếp theo thứ tự version
- Sử dụng hai bảng:
    - Bảng Event để store event
    - Bảng Undispatched Event để lưu tạm các event chờ gửi, sẽ xóa sau khi gửi xong.

#### Đảm bảo thứ tự nhận message

- Gom nhóm các message theo một định danh: ví dụ aggregate id
- Các message của một nhóm chỉ được nhận bởi một thread tại một
    thời điểm
- Tận dụng các tính năng Partition của Kafka hoặc Session của Windows
    Service Bus để đảm bảo thứ tự message khi routing

// ref:     
- https://tungexplorer.s3.ap-southeast-1.amazonaws.com/other_file/DDD_EventDrivenArchitecture.pdf
- https://youtu.be/glZs4QFfwbc