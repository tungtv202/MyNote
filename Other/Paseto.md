---
title: PASETO - Token base authentication
date: 2020-04-19 18:00:26
updated: 2024-07-28 18:00:26
tags:
    - paseto
    - token
    - authen
category: 
    - other
---

# 1. Use Cases

## 1.1. Use Case 1

You are building a system with two applications:
- **Web application:** Allows users to pay for file downloads.
- **Download service application:** Provides the file download service via a link containing a token from the Web Application.

### Desired Scenario:
- The user makes a payment on the website.
- The website verifies the payment and generates a download link (with a token), returning it to the user.
- The user uses the download link to download the file.

**Problem:** How can the Download service validate the download request URL without querying the database?

## 1.2. Use Case 2

You are building two systems:
- **Authorization service:** Manages user login and permissions.
- **Website:** Allows user login.

### Desired Scenario:
- The user accesses the website and logs in.
- The website redirects the user to the authorization service.
- The user fills in the login form at the authorization service.
- The authorization service verifies the credentials and redirects the user back to the website with a token.
- The website receives the token, validates it, and creates a user session.

**Problem:** How can the website ensure the token is valid and issued by the authorization service, preventing middle-man attacks?

# 2. PASETO

- PASETO (Platform-Agnostic SEcurity TOkens) is a protocol for token-based authentication.
- It is a stateless token, meaning it can validate itself without needing additional storage or queries.
- PASETO has two modes: LOCAL (for use case 1) and PUBLIC (for use case 2).

## 2.1 LOCAL Mode

Token format: `v1.local.payload.optional_footer`

### Example:
```
v1.local.CuizxAzVIz5bCqAjsZpXXV5mk_WWGHbVxmdF81DORwyYcMLvzoUHUmS_VKvJ1hn5zXyoMkygkEYLM2LM00uBI3G9gXC5VrZCUM.BLZo1q9IDIncAZTxYkE1NUTMz
```
- **v1:** PASETO version.
- **local:** LOCAL mode.
- **payload:** A JSON object, encrypted.
- **optional_footer:** Contains metadata, not encrypted.

### How it works:
LOCAL mode uses symmetric encryption, meaning the same key is used for both encryption and decryption (e.g., AES algorithm).

### JSON Payload Fields:
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

- Typically, the `exp` and `iat` fields are used to check the token's validity period.

### Example for solving use case 1:
![Baitoan1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/paseto/baitoan1.gif)

## 2.2 PUBLIC Mode

Token format: `v1.public.payload.optional_footer`

### How it works:
PUBLIC mode uses asymmetric encryption, meaning there is a pair of keys: 
a private key for encryption and a public key for decryption.

![Format](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/paseto/format.JPG)

### Example for solving use case 2:
![Baitoan2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/paseto/baitoan2.gif)

# 3. Comparison between PASETO and JWT

## 3.1 Similarities
- Both are protocols for token-based authentication.
- Payload is a JSON object.
- Both are stateless tokens.
- Both include an "expire time" field in the payload to check the token's validity period.

## 3.2 Differences
| Difference            | JWT                                          | PASETO                                      |   
|-----------------------|----------------------------------------------|---------------------------------------------|
| Self-validation method| Decode payload + header with base64, then hash with the secret key | Decrypt payload with shareKey or publicKey |
| Number of modes       | Only 1 mode                                  | Two modes: local and public, chosen based on use case |

## 3.3 Weaknesses of JWT
- An attacker can modify the `alg` field in the header to change the hashing algorithm to a weaker one, increasing vulnerability if the server does not check `alg`.

# 4. References

## 4.1 Algorithms
- **v1.local:** AES-256-CTR + HMAC-SHA384.
- **v1.public:** 2048-bit RSA.
- **v2.local:** XChaCha20-Poly1305.
- **v2.public:** Ed25519.

## 4.2 Related Links
- [Original article](https://developer.okta.com/blog/2019/10/17/a-thorough-introduction-to-paseto)
- [PASETO homepage](https://paseto.io)
- [NoWayJoseCPV2018](https://docs.google.com/presentation/d/1Rn4xQWB0NCKvy7_lcyowZGz0QPvbAskGjNdYLmuQMhY)

**Note:** When experimenting with `v2`, you may need to install `sodium` for OS support for the algorithms used in PASETO.
