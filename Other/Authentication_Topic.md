---
title: Authentication Topic
date: 2020-02-17 18:00:26
updated: 2021-12-08 18:00:26
tags:
    - authentication
    - basic
    - session
    - token
category: 
    - other
---

## 1. Basic Authentication

- `Authorization: Basic YWJjOjEyMw== `  trong đó `YWJjOjEyMw==` là `base64encode` của `abc:123`  (username = abc,
  password = 123)

![BasicAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/basicAuthFlow.jpg)

## 2. Session-based Authentication

- Session ID sẽ xuất hiện trong các HTTP request tiếp theo trong Cookie (header `Cookie: SESSION_ID=abc`)

![SessionAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/Session-based_Authentication.jpg)

## 3. Token-based Authentication

- Token thường có tính self-contained (như JWT), tức là có thể tự kiểm tra tính đúng đắn nhờ vào các thuật toán mã hóa
  và giải mã chỉ dựa vào thông tin trên token và 1 secret key nào đó của server. Do đó server không cần thiết phải lưu
  lại token, hay truy vấn thông tin user để xác nhận token.
- Token sẽ xuất hiện trong các HTTP request tiếp theo trong Authorization header.

(`Authorization: Bearer abc`)
![TokenAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/TokenBased.jpg)

## 4. Compare

![Compare](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/compare.JPG)

## 5. OAuth 2.0

![Oauth2.0](https://shopify.dev/assets/api/oauth-code-grant-flow.png)

- The merchant requests to install the app.
- The app redirects to Shopify to load the OAuth grant screen and requests the required scopes.
- Shopify displays a prompt to receive authorization and prompts the merchant to login if required.
- The merchant consents to the scopes and is redirected to the redirect_uri.
- The app makes an access token request to Shopify including the client_id, client_secret, and code.
- Shopify returns the access token and requested scopes.
- The app uses the token to make requests to the Shopify API.
- Shopify returns the requested data.
  [ref](https://shopify.dev/tutorials/authenticate-with-oauth)

## 6. OIDC - openId connect
- oidc = extend oauth

### id token vs access token?
- id token
  - SHOULD: get info of user, example birthday, address...
  - SHOULD: app -> id provider  (Spring oauth use id_token for call api get userInfo to ID provider)
  - SHOULD NOT: for authorizing
  - SHOULD NOT: client -> app
- access token
  - SHOULD: for authorizing
  - SHOULD: client -> app, app -> id provider
  
### Authorization Code Flow vs PKCE
- PKCE is extending of Authorization Code
- Authorization Code need `clientId`  AND `clientSecret` (use in step: App -> Authorization Server) 
  - SHOULD NOT use it in SPA (can implement by Reactjs, AngularJs, that we don't have a backend authorization). Because user can use the web browser to get `clientSecret`
  - SHOULD: traditional web app, like as thymeleaf with spring boot 
- PKCE: more secure
  - client app (reactjs) NEED create a `code_verifier` (it may be random string). `HASH(code_verifier) = code_challenge`. 
  - Then, client app sends `code_challenge` to Authorization Server.
  - Authorization Server will store the `code_challenge` for later verification
  - after the user authenticates, redirects back to the app with an authorization code. The app makes the request to exchange the code for tokens, only it sends the Code Verifier instead of a fixed secret. Now the Authorization Server can hash the Code Verifier and compare it to the hashed value it stored earlier.
![PKCE Flow](https://developer.okta.com/assets-jekyll/blog/okta-authjs-pkce/pkce-59cd81484ee5be4248d4f8efc986070d7d6ac20b8091da3b8377bf1e278a0b54.svg)

### What is JWKS URI?
- JWKS = JSON web key set 
- JWKS URI = endpoint to get public key, in order to use the public key for the verification token
- Often this endpoint has suffix is `.well-known/jwks.json`
  - But in keycloak, it has format `/auth/realms/realm1/protocol/openid-connect/certs`
  - Format look like this: 

```json
{
    "keys": [
        {
            "kid": "mpRkvfWFRXvrmbr_TuiSboWX8PJXIk9jDw-S98_9Yfw",
            "kty": "RSA",
            "alg": "RS256",
            "use": "sig",
            "n": "qyXuEh5ITO4xaHP2OilF-zi7B-ijvDNvY1AqKUQAqroKSHVTjR5G8jjYKh3vs_-eRc3oIve0l_GnM88L2DwmOFzDYLUTMbc37cb3sd6sZvHeohUMHDSblZHBWkGPUBcAz-7cP5C1ZU6Z9lGSOOSVjsxYMloUi-RrjrtMzC0cgdbCUDxycJLbxH6DR8_pf0_-P30cxwMl6DtDkS4bcHILiWkTaGts-Dw0VF1XU6Dl4MiTp9xPmfeGmoxHGSlDH_--DxY5qESVNRjZt3NcvOGHCwYmZNU0ocUfvJnpdLocaqPbGBYaxVOuFcia52GNlx3rjhpQDJjpiPYb4SMhp5RewQ",
            "e": "AQAB",
            "x5c": [
                "MIICmzCCAYMCBgF9mvWlFzANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZyZWFsbTEwHhcNMjExMjA4MTY1MDI5WhcNMzExMjA4MTY1MjA5WjARMQ8wDQYDVQQDDAZyZWFsbTEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCrJe4SHkhM7jFoc/Y6KUX7OLsH6KO8M29jUCopRACqugpIdVONHkbyONgqHe+z/55Fzegi97SX8aczzwvYPCY4XMNgtRMxtzftxvex3qxm8d6iFQwcNJuVkcFaQY9QFwDP7tw/kLVlTpn2UZI45JWOzFgyWhSL5GuOu0zMLRyB1sJQPHJwktvEfoNHz+l/T/4/fRzHAyXoO0ORLhtwcguJaRNoa2z4PDRUXVdToOXgyJOn3E+Z94aajEcZKUMf/74PFjmoRJU1GNm3c1y84YcLBiZk1TShxR+8mel0uhxqo9sYFhrFU64VyJrnYY2XHeuOGlAMmOmI9hvhIyGnlF7BAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAA4osUItTVx4ZfZCE0pwrHXlxxioBRj/BB5eGhJjTR8ZK4B30hbyv5BJn04sRDOZmagEFn1xTUjpTyPHzH3thdqSDIqsWrxI1fwCY8l8KD/NeigP25CJn+Zn5YO/2+SfN7JP4eeE4PjhjVVFNTP+UBuMUaGEnbw4yhZZxAYuF4rUOPGJ1V7Fc22d8r8gBIMykIvipdGFDIypQj2Cearitqs5/6P+9WiLHlBiiwiNTr5FmVhk3HVcxKSk8pzEhl85RHUT60Hn/82how28vjSLmdY2n6ApkhauUoNUJvsHdhmJhptMIKLAGTSc4Jl+qOg+y7TcL5dvNqbdXy5bn3m2LC8="
            ],
            "x5t": "bD7dNY4UHbG95tFBievhD1WXcEU",
            "x5t#S256": "wN9C1fwn8V6MGs0J3ymKAFa7GF7Kah9OsnXmopkJV58"
        },
        {
            "kid": "FP2Ie6xKpFRDYXpaJanHWL0GlMLMNDc9St38x6TevbM",
            "kty": "RSA",
            "alg": "RS256",
            "use": "enc",
            "n": "l8PegYQQYtLmXyQ4ItwlCbUsK7TmjBgi1BtqUhPyyhea4OIflIulkgPOE2Jj4-vHCVbdvFFZkmLwQpu2nUm_cG9m-R2L6h9WGmBG0oIg4c-mm3XjLEbv0j86wAhqIXrh7Xbuyk2zwZZsHWjYqONOVMkN71cpWgmTbsjBjfEgdKdlOX3yIHVlILyQopH9gIsokTHbSxuYaZFh2JWkCQ_TyLgvvUs0VYtkLPFhw5oLkn4SpI6e2vqNsZSgiYAN1UdfxhNUGFKijPY7cK76WxTR18N3baD9jzUpmuJL1dvIJlXR9XwqAVSpbf-Uzu6-ajT7JGGK5kLHLQf4-T9jXLaMwQ",
            "e": "AQAB",
            "x5c": [
                "MIICmzCCAYMCBgF9mvWlSDANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZyZWFsbTEwHhcNMjExMjA4MTY1MDI5WhcNMzExMjA4MTY1MjA5WjARMQ8wDQYDVQQDDAZyZWFsbTEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCXw96BhBBi0uZfJDgi3CUJtSwrtOaMGCLUG2pSE/LKF5rg4h+Ui6WSA84TYmPj68cJVt28UVmSYvBCm7adSb9wb2b5HYvqH1YaYEbSgiDhz6abdeMsRu/SPzrACGoheuHtdu7KTbPBlmwdaNio405UyQ3vVylaCZNuyMGN8SB0p2U5ffIgdWUgvJCikf2AiyiRMdtLG5hpkWHYlaQJD9PIuC+9SzRVi2Qs8WHDmguSfhKkjp7a+o2xlKCJgA3VR1/GE1QYUqKM9jtwrvpbFNHXw3dtoP2PNSma4kvV28gmVdH1fCoBVKlt/5TO7r5qNPskYYrmQsctB/j5P2NctozBAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAD9FUakmwBYASe0W7CMX31B4SxkxW3kpSiN87LZg9KszAEF4nUSIAtmO21s9RDND5cQh3sxrS+ONVx36BU2xYBzoBeijAYFqjAr4ZpwBR6KPHAEQpalKog9zmEgR1Pki648zedi80gkFCxm6TXI4DY760ThvGzjkbfYFd2YSf+i1RWTq8NAqzUx0UTPNO3cCkRYOQ7Hrb5EpSXIgXjm3fG2/HyyB2Jvwb9yU6ffvg0FrUqiytChFxLeqhLoUEBNdiw0CroyeKaiYaNkZTwD9EwkUq6OXkqW5XHceM30oT4G2CXGNR9Al2oQi5kdYG6W+th0acZzeh+raDawrWGZpYic="
            ],
            "x5t": "V0xH-oSQYY8Xm_tro1n9bIZjcBU",
            "x5t#S256": "VGwU3h3_Z5d2LdEsW1FRrmiCDJDm85pLnyReExQ9nY8"
        }
    ]
}
```
- Need pay attention to `kid` property, it help we detect the exactly public_key for any token. (`kid` will be contains in header of jwt token)
### Note
- `state`, `session_state`: for CSRF
- Spring debug at class: `org.springframework.security.oauth2.client.oidc.authentication.OidcAuthorizationCodeAuthenticationProvider`
- When `credential` mode: client_id + client_secret = username + password. It implicit is `Basic Auth`

### Why does OAuth server return a authorization code instead of access token in the first step?
- https://stackoverflow.com/questions/13387698/why-is-there-an-authorization-code-flow-in-oauth2-when-implicit-flow-works-s
- https://www.quora.com/Why-does-OAuth-server-return-a-authorization-code-instead-of-access-token-in-the-first-step
