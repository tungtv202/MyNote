# Authentication topic
## 1. Basic Authentication
- `Authorization: Basic YWJjOjEyMw== `  trong đó `YWJjOjEyMw==` là `base64encode` của `abc:123`  (username = abc, password = 123)   

![BasicAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/basicAuthFlow.jpg)

## 2. Session-based Authentication
- Session ID sẽ xuất hiện trong các HTTP request tiếp theo trong Cookie (header `Cookie: SESSION_ID=abc`)

![SessionAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/Session-based_Authentication.jpg)

## 3. Token-based Authentication
- Token thường có tính self-contained (như JWT), tức là có thể tự kiểm tra tính đúng đắn nhờ vào các thuật toán mã hóa và giải mã chỉ dựa vào thông tin trên token và 1 secret key nào đó của server. Do đó server không cần thiết phải lưu lại token, hay truy vấn thông tin user để xác nhận token.
- Token sẽ xuất hiện trong các HTTP request tiếp theo trong Authorization header.   

(`Authorization: Bearer abc`)
![TokenAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/TokenBased.jpg)

## 4. Compare 
![Compare](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/compare.JPG)