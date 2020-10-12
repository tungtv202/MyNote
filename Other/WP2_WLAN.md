---
title: WPA2 on WLAN
date: 2019-02-18 18:00:26
tags:
    - network
    - security
    - wlan
    - wpa
category: 
    - other
---


# Hoạt động giao thức bảo mật WPA2 trong WLAN

## 1. Tổng quan
WPA2 ( hay chuẩn IEEE 802.11i) được chứng nhận bởi WiFI Alliance, sử dụng thuật toán mã hóa mạnh mẽ và được gọi là chuẩn mã hóa nâng cao AES(Advance Encrypt Standard), sử dụng thuật toán mã khóa đối xứng theo khối 128 bit, 192 bit hoặc 256 bit.    
Thay vì sử dụng giao thức TKIP có trong WPA, WPA2 sử dụng giao thức CCMP được cải tiến và nâng cao hơn.     
WPA2 có hai chế độ sử dụng là WPA2 Personal dành cho mạng gia đình, cá nhân, doanh nghiệp nhỏ, WPA2 Enterprise dành cho mạng doanh nghiệp vừa và lớn. Điểm khác biệt ở hai chế độ này là ở bước xác thực người dùng.    
WPA2 bao gồm 3 quá trình:   
- Xác thực người dùng.    
- Quá trình mã hóa.   
- Quá trình giải mã.  

## 2. Xác thực người dùng trong WPA2 Enterprise
### a. Quy trình    
Quá trình xác thực này được xây dựng dựa trên chuẩn 802.1X, gồm 3 bên (3 thiết bị):
Bên xin kết nối (Supplicant)/ Client là các máy tính hay thiết bị nằm trong vùng phủ sóng WiFi. 
Bên xác thực (Authenticator)/ AP là Access Point, thiết bị phát sóng, có vai trò trung gian. Chuyển tiếp giữa Client và Authenticator Server.	    
Bên sever xác thực (Authenticator Server), sử dụng Radius Server, là thiết bị chính, có khả năng cấp quyền cho Client được phép truy cập hay không.
![WPA2_1](https://i.imgur.com/yIczarL.png)
Các bước:   
- Bước 1:     
Client gửi yêu cầu xin kết nối mạng WiFI tới thiết bị AP.   
AP yêu cầu Client cung cấp ID của mạng. 
Client cung cấp ID, AP sẽ chuyển tiếp gói tin này tới Radius Server xin xử lý xác thực.
Sau bước này, AP và Client sẽ đồng ý các chính sách bảo mật, phương thức xác thực, giao thức cho truyền thông (giao thức EAP-PoL).  

- Bước 2: Diễn ra trực tiếp giữa Radius và Client 
Radius Server yêu cầu Client chứng thực. Bằng cách tạo ra số ngẫu nhiên Gnonce, và được mã hóa lại với khóa của Radius. Gửi dữ liệu mã hóa này cho Client.
Client nhận được gói tin, giải mã, lấy giá trị Gnonce, sau đó mã hóa lại với khóa riêng của Client. 
Radius nhận được gói tin, tiễn hành  giải mã, và so sánh giá trị Gnonce, nếu đúng bằng giá trị ban đầu. Ra quyết định đồng ý kết nối. Ngược lại, hủy kết nối, quá trình xác thực không thành công.  

- Bước 3:     
Radius Server sẽ tính toán ra một khóa mới, sử dụng cho phiên làm việc. Ở đây tạm gọi là khóa MK( Master Key).  
Radius Server sẽ gửi khóa này cho cả AP, và Client. Đồng thời cho AP biết, quyền hạn kết nối của Client.    
Sau bước này, cả Client và AP cùng nắm giữ khóa PMK( Pairwise Master Key).      

- Bước 4: 
Client và AP thực hiện trao đổi dữ liệu với nhau.   
Tất cả các khóa được sinh trước đó được dùng bởi giao thức CCMP để cung cấp tính bí mật  và toàn vẹn của dữ liệu.       
### b. 4 Way Handshake
Bên tham gia: AP và Client  
Đầu vào: PMK        
Đầu ra: PTK và GTK      
![WPA2_2](https://i.imgur.com/8SRLlqt.png)
Được thực hiện bởi 4 thông điệp EAPoL-Key ( thông điệp được sử dụng ở lớp 2 - tầng liên kết dữ liệu, EAPoL ( EAP over LAN)).    
- Bước 1.     
AP khởi tạo ngẫu nhiên giá trị A Nonce  
Gửi A Nonce cho Client  

- Bước 2.     
Client khởi tạo giá trị nhẫu nhiên S Nonce  
Khởi tạo MIC và gửi cho AP. 
Sử dụng PMK, S Nonce, A Nonce, MAC của Client và AP để tính ra PTK.    

- Bước 3. 
Dựa vào PMK, A Nonce, MAC của Client và AP, và S Nonce vừa nhận được, tính toán ra PTK.     
Xác thực MIC.   
Khởi tạo GMK. Tính toán GTK (128 bit với CCMP).     
Tạo MIC mới. Gửi MIC và GTK cho Client  

- Bước 4. 
Báo cáo hoàn thành kết nối.     
Client cài đặt GTK, tính toán giá trị MIC để chắc chắn rằng AP biết PMK.

Chú ý: Khóa GTK sẽ được làm mới bởi quá trình Group Key Handshake. 
Phân biệt giữa GTK và TK:
Cả 2 khóa đều được dùng vào việc mã hóa và giải mã dữ liệu. Tuy nhiên GTK ( khóa dùng chung tạm thời), được chia sẻ giữa tất cả các máy khách được cấp quyền trong một mạng WPA2, được sử dụng trong các gói tin broadcast/multicast. Khóa TK được sử dụng trong các gói tin Unicast.       

### c. Group Key Handshake
Được kích hoạt khi có yêu cầu làm mới GTK.  
Đầu vào: PTK    
Đầu ra: GTK (đã được làm mới)   
![WPA2_3](https://i.imgur.com/t2kn8PI.png)

- Bước 1. 
AP khởi tạo ngẫu nhiên Gnonce, cộng với GMK đã có, tính toán GTK mới, được mã hóa lại bằng KEK.     
Gửi giá trị GTK, MIC tới AP.    
- Bước 2.     
Client giải mã GTK, xác thực MIC.   
Gửi lại giá trị MIC cho AP. 
Sau khi xác thực MIC thành công, AP cài đặt GTK mới.    

## 3. Thuật toán mã hóa AES trong WPA2  
WPA2 sử dụng  AES và CCMP (có thể thay thế bằng TKIP để sử dụng trên thiết bị dùng WPA), độ dài từ khóa là 128bits, 192bits hoặc 256bits.   
Xếp theo độ phức tạp thì AES, CCMP > TKIP > RC4, yêu cầu phần cứng cũng tương ứng theo độ phức tạp. AES là phương pháp mã hóa tốt nhất hiện nay, việc crack AES được coi là bất khả thi.    
Việc sử dụng thuật toán phức tạp hơn tăng đồng thời chi phí thám mã và thời gian thám mã, khiến WPA2(AES,CCMP) trở thành phương pháp bảo mật tốt nhất cho mạng wifi 
