---
title: Authentication Topic
date: 2020-02-17 18:00:26
updated: 2024-07-28 18:00:26
tags:
    - authentication
    - basic
    - session
    - token
category: 
    - other
---

## 1. Basic Authentication

- The `Authorization` header for Basic Authentication looks like this: `Authorization: Basic YWJjOjEyMw==`. Here, `YWJjOjEyMw==` is the `base64` encoded string of `abc:123` (username = abc, password = 123).

![BasicAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/basicAuthFlow.jpg)

## 2. Session-based Authentication

- The Session ID will appear in subsequent HTTP requests within the Cookie header (e.g., `Cookie: SESSION_ID=abc`).

![SessionAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/Session-based_Authentication.jpg)

## 3. Token-based Authentication

- Tokens, often self-contained (like JWT), can be verified for correctness using encryption and decryption algorithms based on the token's information and a secret key of the server. Therefore, the server does not need to store the token or query user information to verify the token.
- The token will appear in subsequent HTTP requests within the Authorization header (e.g., `Authorization: Bearer abc`).

![TokenAuthen](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/TokenBased.jpg)

## 4. Comparison

![Compare](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/authen_topic/compare.JPG)

## 5. OAuth 2.0

![Oauth2.0](https://shopify.dev/assets/api/oauth-code-grant-flow.png)

1. The merchant requests to install the app.
2. The app redirects to Shopify to load the OAuth grant screen and requests the required scopes.
3. Shopify displays a prompt to receive authorization and prompts the merchant to log in if required.
4. The merchant consents to the scopes and is redirected to the `redirect_uri`.
5. The app makes an access token request to Shopify including the `client_id`, `client_secret`, and code.
6. Shopify returns the access token and requested scopes.
7. The app uses the token to make requests to the Shopify API.
8. Shopify returns the requested data.

[Reference](https://shopify.dev/tutorials/authenticate-with-oauth)

## 6. OIDC - openId connect
- OIDC = extends OAuth 2.0.

### ID Token vs Access Token

- **ID Token**:
  - SHOULD: Be used to get information about the user, such as birthday, address, etc.
  - SHOULD: Be used by the app to get user info from the ID provider (e.g., Spring OAuth uses `id_token` to call API and get user info from the ID provider).
  - SHOULD NOT: Be used for authorizing.
  - SHOULD NOT: Be sent from client to app.

- **Access Token**:
  - SHOULD: Be used for authorizing.
  - SHOULD: Be sent from client to app and from app to ID provider.

### Authorization Code Flow vs PKCE

- PKCE is an extension of Authorization Code Flow.
- Authorization Code Flow requires `clientId` and `clientSecret` (used in the step: App -> Authorization Server).
  - SHOULD NOT: Be used in Single Page Applications (SPAs) (e.g., React.js, AngularJS) because users can access `clientSecret` from the web browser.
  - SHOULD: Be used in traditional web apps (e.g., Thymeleaf with Spring Boot).

- **PKCE**: More secure.
  - The client app (e.g., React.js) needs to create a `code_verifier` (a random string). `HASH(code_verifier) = code_challenge`.
  - The client app sends the `code_challenge` to the Authorization Server.
  - The Authorization Server stores the `code_challenge` for later verification.
  - After the user authenticates, they are redirected back to the app with an authorization code. The app requests to exchange the code for tokens, sending the `code_verifier` instead of a fixed secret. The Authorization Server hashes the `code_verifier` and compares it to the stored hashed value.

![PKCE Flow](https://developer.okta.com/assets-jekyll/blog/okta-authjs-pkce/pkce-59cd81484ee5be4248d4f8efc986070d7d6ac20b8091da3b8377bf1e278a0b54.svg)

### What is JWKS URI?

- **JWKS**: JSON Web Key Set.
- **JWKS URI**: Endpoint to get the public key, used for token verification.
- This endpoint often has the suffix `.well-known/jwks.json`.
  - In Keycloak, it has the format `/auth/realms/realm1/protocol/openid-connect/certs`.
  - The format looks like this:

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

- Pay attention to the `kid` (Key ID) property, which helps identify the exact public key for any token. The `kid` is contained in the header of a JWT token.

### Notes

- `state`, `session_state`: Used for CSRF protection.
- Spring debug class: `org.springframework.security.oauth2.client.oidc.authentication.OidcAuthorizationCodeAuthenticationProvider`.
- In `credential` mode: `client_id + client_secret` is equivalent to `username + password`. This is implicitly `Basic Auth`.

### Why does the OAuth server return an authorization code instead of an access token in the first step?

- [Stack Overflow Discussion](https://stackoverflow.com/questions/13387698/why-is-there-an-authorization-code-flow-in-oauth2-when-implicit-flow-works-s)
- [Quora Discussion](https://www.quora.com/Why-does-OAuth-server-return-a-authorization-code-instead-of-access-token-in-the-first-step)
- [HTTPWatch Blog](https://blog.httpwatch.com/2011/03/01/6-things-you-should-know-about-fragment-urls/)

