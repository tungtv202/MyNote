---
title: Authentication Topic
date: 2020-02-17 18:00:26
tags:
    - authentication
    - basic
    - session
    - token
category: 
    - other
---

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

## 5. OAuth 2.0 
![Oauth2.0](https://shopify.dev/assets/api/oauth-code-grant-flow.png)
- The merchant makes a request to install the app.
- The app redirects to Shopify to load the OAuth grant screen and requests the required scopes.
- Shopify displays a prompt to receive authorization and prompts the merchant to login if required.
- The merchant consents to the scopes and is redirected to the redirect_uri.
- The app makes an access token request to Shopify including the client_id, client_secret, and code.
- Shopify returns the access token and requested scopes.
- The app uses the token to make requests to the Shopify API.
- Shopify returns the requested data.
[ref](https://shopify.dev/tutorials/authenticate-with-oauth)