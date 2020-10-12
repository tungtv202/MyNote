---
title: Paseto - Token base authentication
date: 2020-04-19 18:00:26
tags:
    - paseto
    - token
    - authen
category: 
    - other
---

# 1. Bài toán / Best use case
## 1.1. Bài toán 1
- Bạn xây dựng 1 hệ thống. Gồm 2 application:
    - Web application: cho phép user trả tiền để download file.  
    - Download service application: cung cấp service tải file (user dùng url Web Application trả về, để request tải)
    - 2 application này có 1 kênh kết nối an toàn vs nhau. (ví dụ cùng mạng LAN, kết nối sử dụng private IP..)
- Kịch bản mong muốn:
    - User thực hiện thanh toán trên Website
    - Website xác thực việc thanh toán hoàn tất. Và tạo link download (có kèm token), trả về cho user
    - User sử dụng link download để tải xuống.  

Làm thế nào để Download service validate được url request download?...Mà không phải call tới bất kỳ database nào. (kiểu không query tới db để check token, check lịch sử thanh toán...)

## 1.2. Bài toán 2
- Bạn xây dựng 2 hệ thống:
    - Hệ thống cung cấp dịch vụ authorization. Quản lý việc user login, và cấp quyền
    - Hệ thống Website, cho phép user login
    - 2 hệ thống này có 1 kênh kết nối không đảm bảo chắc chắn an toàn. (Ví dụ: hệ thống authorization sau này không chỉ cung cấp cho 1 website kia, mà còn cho bất website khác. Kiểu như OpenID, OAuth 2...)
- Kịch bản mong muốn: 
    - User truy cập website và login (vd: https://example.com/login)
    - Website điều hướng user về hệ thống authorization (vd: https://authorization-ex.com)
    - User điền thông tin username/password tại form login của authorization service.
    - Authorization Service xác thực tài khoản + điều hướng user về website, kèm token. (https://example.com/authen?token=abcxyz)
    - Website nhận được token. Thực hiện validate, và tạo session truy cập cho user.
    - User truy cập Website sử dụng session được cấp.

Làm thế nào để Website đảm bảo được token đúng là của Authorization Service tạo? (Phòng ngừa kiểu tấn công Middle-Man)

# 2. PASETO
- PASETO = Platform-Agnostic SEcurity TOkens
- Là một prototol cho bài toán Token-based authentication
- Là 1 Stateless token (tức là tự bản thân nó có khả năng validate, mà không cần phải lưu trữ / truy vấn thêm ở đâu)
- Có nhiều nét tương đồng với JWT (JSON Web Tokens), nhưng "nâng cấp" hơn.  
- PASETO có 2 mode:
    - LOCAL  (được dùng cho bài toán 1 bên trên)
    - PUBLIC (được dùng cho bài toán 2 bên trên)
## 2.1 Mode LOCAL
- Token format: `v1.local.payload.optional_footer` 
    - Exxample:
        ```
        v1.local.CuizxAzVIz5bCqAjsZpXXV5mk_WWGHbVxmdF81DORwyYcMLvzoUHUmS_VKvJ1hn5zXyoMkygkEYLM2LM00uBI3G9gXC5VrZCUM.BLZo1q9IDIncAZTxYkE1NUTMz
        ```
    - v1: là `version` của PASETO. Việc lựa chọn version sẽ quyết định loại thuật toán được sử dụng để mã hóa. (Version càng cao, thì thuật toán mã hóa càng mới, càng có tính bảo mật cao, nhưng nhược điểm là cần thiết bị tương thích). Hiện tại đang chỉ có 2 version v1, v2
    - local: là mode LOCAL
    - payload: 1 object json, sau đó được mã hóa.
    - optional_footer: có thể có hoặc không. Được dùng để chứa metadata. Và không được mã hóa.
- Mode LOCAL sử dụng kiểu mã hóa đối xứng - `Symmetric` (tức là khóa để encrypt và khóa để decrypt là giống nhau). Vd: giải thuật AES
- Các phiên bản Paseto không có tính tương thích ngược. Tức là bên mã hóa dùng version nào, thì bên giải mã cũng phải dùng version đó.
- Tên các trường trong object json ở payload theo chuẩn của [PASETO RFC](https://paseto.io/rfc/)
    ```text
    +-----+------------+--------+-------------------------------------+
    | Key |    Name    |  Type  |               Example               |
    +-----+------------+--------+-------------------------------------+
    | iss |   Issuer   | string |       {"iss":"paragonie.com"}       |
    | sub |  Subject   | string |            {"sub":"test"}           |
    | aud |  Audience  | string |       {"aud":"pie-hosted.com"}      |
    | exp | Expiration | DtTime | {"exp":"2039-01-01T00:00:00+00:00"} |
    | nbf | Not Before | DtTime | {"nbf":"2038-04-01T00:00:00+00:00"} |
    | iat | Issued At  | DtTime | {"iat":"2038-03-17T00:00:00+00:00"} |
    | jti |  Token ID  | string |  {"jti":"87IFSGFgPNtQNNuw0AtuLttP"} |
    | kid |   Key-ID   | string |    {"kid":"stored-in-the-footer"}   |
    +-----+------------+--------+-------------------------------------+
    ```
- Thường field `exp` + `iat` được sử dụng để check thời hạn của token.

// :-? Một trong những điểm mà mình không thích ở JWT, đó là phần payload của JWT chỉ được decode bởi base64. Nó như kiểu là "tao cho mày xem thông tin đấy, nhưng mày xem thấy cũng chả làm được gì đâu"

- Lời giải cho bài toán 1 dùng PASETO.
    ![Baitoan1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/paseto/baitoan1.gif)

## 2.2 Mode PUBLIC
- Token format: `v1.public.payload.optional_footer` 
    - Format giống với mode LOCAL
- Payload ở mode PUBLIC được mã hóa/ giải mã bởi kiểu mã hóa BẤT đối xứng - `ASymmetric` (tức là sẽ có 1 cặp khóa, privateKey và publicKey riêng biệt. PrivateKey dùng để mã hóa. PublicKey dùng để giải mã. Kiểu như: ai cũng có thể giải mã, nhưng chỉ 1 người mới có thể mã hóa). Vd: giải thuật RSA

    ![Format](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/paseto/format.JPG)
- Lời giải cho bài toán 2:
    ![Baitoan2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/paseto/baitoan2.gif)


# 3. So sánh PASETO vs JWT
## 3.1 Giống nhau
- Đều là protocol cho bài toán Token-based authentication
- Payload đều là object json
- Đều là staless token
- Tư tưởng phần `payload` đều có trường "expire time", để check hạn sử dụng của token
- Đều không có khả năng chống replay attack. (tức token bị lọt vào tay attacker, thì attacker có thể sử dụng nó như chính user thật)

## 3.2 Khác nhau

|   Sự khác biệt	|   JWT	|   PASETO	|   
|---	|---	|---	|
|   Cách self validate (tự check chữ ký)	|   phần payload + header được decode bởi base64, sau đó sẽ được băm `hash` với giải thuật được khai báo ở header, có sử dụng secret key. Rồi sau đó so sánh với phần signature	| phần payload được decrypt bởi shareKey (hoặc publicKey), nếu decrypt thành công tức token hợp lệ  	| 
|Số mode | chỉ có 1 mode | có 2 mode: local + public, tùy use case mà lựa chọn|


## 3.3 Điểm yếu của JWT
- Attacker có thể sửa trường `alt` ở header, để thay đổi giải thuật băm, bằng 1 hàm băm có độ bảo mật yếu, đồng thời sửa `signature`. Nếu phía server không thực hiện check `alt`, thì sẽ tăng nguy cơ bị hổng.

# 4. Reference
## 4.1 Algorithm
- v1.local: AES-256-CTR + HMAC-SHA384 (Encrypt-then-MAC)
- v1.public: 2048-bit RSA
- v2.local: XChaCha20-Poly1305 (192-bit nonce, 256-bit key, 128-bit authentication tag)
- v2.public: Ed25519 (EdDSA over Curve25519)

## 4.2 Link liên quan
- Bài viết được viết lại từ: https://developer.okta.com/blog/2019/10/17/a-thorough-introduction-to-paseto
- Trang chủ paseto: https://paseto.io
- NoWayJoseCPV2018: https://docs.google.com/presentation/d/1Rn4xQWB0NCKvy7_lcyowZGz0QPvbAskGjNdYLmuQMhY


- Lưu ý: khi code thử nghiệm với `V2`, có thể sẽ cần phải cài đặt thêm `sodium`, để OS có hỗ trợ giải thuật được sử dụng trong PASETO. (Vì các giải thuật trong V2 khá mới, nên OS có thể không có sẵn)