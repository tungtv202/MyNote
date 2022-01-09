---
title: Lab - KrakenD + Keycloak + SSO, SLO
date: 2022-01-09 15:31:26
updated: 2022-01-09 15:31:26
tags:
    - oauth2
    - keycloak
    - krakend
    - sso
    - slo
category: 
    - other
---

# Lab - KrakenD + Keycloak: SSO, SLO

## API backend service

- https://end4tawjnxl4skw.m.pipedream.net (This is a public endpoint, no authentication. Easy to register
  at [https://requestbin.com](https://requestbin.com))
- Verify

```bash
curl https://end4tawjnxl4skw.m.pipedream.net/api/ping

PONG
```

## Krakend Api Gateway

- Routing: http://localhost:8888/ping -> https://end4tawjnxl4skw.m.pipedream.net/api/ping
- Run
  command: `docker run -p 8888:8080 -p 9999:1234 -v "${PWD}:/etc/krakend/" devopsfaith/krakend run -d -c krakend.json`
- Don't forget:
    - 8888: api gateway port -> http://localhost:8888
    - 9999: bloomfilter rpc port (RPC Protocol)
    - This is container network, becareful when declare private host

```json
{
  "version": 2,
  "extra_config": {
    "github_com/devopsfaith/krakend-gologging": {
      "level": "DEBUG",
      "prefix": "[KRAKEND]",
      "syslog": false,
      "stdout": true,
      "format": "default"
    }
  },
  "timeout": "3000ms",
  "cache_ttl": "300s",
  "output_encoding": "json",
  "name": "krakend_keycloak",
  "endpoints": [
    {
      "endpoint": "/ping",
      "method": "GET",
      "output_encoding": "string",
      "extra_config": {
        "github.com/devopsfaith/krakend-jose/validator": {
          "alg": "RS256",
          "jwk-url": "http://172.17.0.1:8180/auth/realms/oauth2-demo-realm/protocol/openid-connect/certs",
          "disable_jwk_security": true,
          "propagate-claims": [
            [
              "email",
              "X-APP-USER"
            ]
          ]
        },
        "github_com/devopsfaith/bloomfilter": {
          "N": 10000000,
          "P": 0.0000001,
          "HashName": "optimal",
          "TTL": 1500,
          "port": 1234,
          "TokenKeys": [
            "sid"
          ]
        }
      },
      "backend": [
        {
          "url_pattern": "/api/ping",
          "encoding": "string",
          "method": "GET",
          "extra_config": {},
          "host": [
            "https://end4tawjnxl4skw.m.pipedream.net"
          ],
          "disable_host_sanitize": false
        }
      ],
      "headers_to_pass": [
        "Accept",
        "Content-Type",
        "Authorization",
        "X-APP-USER"
      ]
    }
  ]
}
```

- For Authen by JWT
    - extra_config `github.com/devopsfaith/krakend-jose/validator`
    - propagate-claims: help you claim value from jwt token, and forward this value to backend api.
    - NOTE: Don't forget declare `headers_to_pass`: X-APP-USER, Authorization
- For Single Log Out (SLO)
    - extra_config `github_com/devopsfaith/bloomfilter`
    - `1234` port for adding `sid` to bloomfilter
    -
  ref [https://www.krakend.io/docs/authorization/revoking-tokens/](https://www.krakend.io/docs/authorization/revoking-tokens/)

## Keycloak

- Run
  command `docker run -p 8180:8080 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin quay.io/keycloak/keycloak:latest`
- Create realm: oauth2-demo-realm
- Create client: oauth2-demo-pkce-client
- Create user: user1-pass

![keycloak_oauth_client_declare](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/oauth2/keycloak_oauth_client_declare.png)

- Don't forget:
    - `Access Type = public`: if you use public app, like as AngularJs
    - `Valid Redirect URI`: this is rule, if not define exactly, you will got "Bad request"
    - `Web Origins = * `: for CORS
    - `BackChannel Logout URL` : for callback when has logout event

## How to get JWT Token?

1. Using postman

![oauth2_getTokenByPostman](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/oauth2/oauth2_getTokenByPostman.png)

2. Using sample app - code by
   AngularJs: [https://github.com/tungtv202/oauth2-pkce-demo-frontend-only](https://github.com/tungtv202/oauth2-pkce-demo-frontend-only)

- Easy to login/logout by UI

![oauth2-frontend-demo](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/oauth2/oauth2-frontend-demo.png)

## Authentication Testing

1. Scenario 1: Call to API Gateway without token

- `GET http://localhost:8888/ping` - without `Authorization` header
- KrakenD log: `Error #01: Token not found`
- HTTP response: `401`

2. Scenario 2: Call to API Gateway with token

```bash
curl --location --request GET 'http://localhost:8888/ping' --header 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia...'
```

- HTTP Respone: `200 - PONG`

## Single Log Out - Revoke Token

1. Mechanism

- Define callback endpoint at keycloak client setting page. (Backchannel Logout URL input form)
- When someone user logout, Keycloak will call HTTP Request to callback endpoint
- Request sample:
  ![oauth2_keycloak_logout_callback_request_sample](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/oauth2/oauth2_keycloak_logout_callback_request_sample.png)

```
logout_token=eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJCMHNsOGpwaUtMMmZyR1lMaWNHTEZURFptTVJWRVVlT01Dcmg0QTNhSG9FIn0.eyJpYXQiOjE2NDE2NzIyMjUsImp0aSI6IjBhYmFmNmZmLTljZmYtNGEzZS1hZTljLTA1MTQ4MGQwMTk2NCIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODE4MC9hdXRoL3JlYWxtcy9vYXV0aDItZGVtby1yZWFsbSIsImF1ZCI6Im9hdXRoMi1kZW1vLXBrY2UtY2xpZW50Iiwic3ViIjoiZDg3NTYzZTYtODhkYS00YTZhLWIyYWMtMmFhZjhlYWY2ZTk1IiwidHlwIjoiTG9nb3V0Iiwic2lkIjoiMDgyMzU2ZGEtNWY3ZS00ZDJkLWE3OWItYTUzMTY1OTRhYTFmIiwiZXZlbnRzIjp7Imh0dHA6Ly9zY2hlbWFzLm9wZW5pZC5uZXQvZXZlbnQvYmFja2NoYW5uZWwtbG9nb3V0Ijp7fSwicmV2b2tlX29mZmxpbmVfYWNjZXNzIjp0cnVlfX0.FeykAYZZj4ehS_43Xjmge7t0mUPyUx8TCcvT8tA32n8eZWbpG5zRRcgR67Lm0CJiKOCwoug4rzHND-DOJ6K_cfocW7PkUoUObPsefAuz5Ljfd9ajIazkQiDCMguLTlEDl3M7pd3vY8W919_Vj9kZ0Or2-UZJlZ7mp5tsPzXi4WxxIpG5Z7f_rX6FblYjqXHV9gFfa1759ngLFFMwUkXoiyHXJ558Pze9RRIjqxbegm8tYWQmGcZxFpdneTWFLFgB2FRT6r2qtwJ76WAT_F8YgO2t76s62hf-Mb8rfg3ahXiEkOr6jMahdutkBI2IRDwkyiz1bIcOx1HEa9iILLzqYg
```

Payload Decode:

```json
{
  "iat": 1641672225,
  "jti": "0abaf6ff-9cff-4a3e-ae9c-051480d01964",
  "iss": "http://localhost:8180/auth/realms/oauth2-demo-realm",
  "aud": "oauth2-demo-pkce-client",
  "sub": "d87563e6-88da-4a6a-b2ac-2aaf8eaf6e95",
  "typ": "Logout",
  "sid": "082356da-5f7e-4d2d-a79b-a5316594aa1f",
  "events": {
    "http://schemas.openid.net/event/backchannel-logout": {},
    "revoke_offline_access": true
  }
}
```

- We need a `middleware`:
    - Receive HTTP request from keycloak
    - Claim `sid` value
    - Add `sid` value to bloom filter of KrakenD via RPC Endpoint: `krakend:1234`
- When the request to Apigateway has `sid` (that claim from jwt token), that existing in bloom filter, the request should be rejected

2. Demo 1

- Sample tool for add `sid` to bloom
  filter: [https://github.com/devopsfaith/krakend-playground/tree/master/jwt-revoker](https://github.com/devopsfaith/krakend-playground/tree/master/jwt-revoker)

![oauth2_krakend_rpc_client_tool_1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/oauth2/oauth2_krakend_rpc_client_tool_1.png)

- Fukkking: when I try to add new sid, I got error: `error on adding bloomfilter: connection is shut down`
  Ref: [https://githubmate.com/repo/devopsfaith/bloomfilter/issues/11](https://githubmate.com/repo/devopsfaith/bloomfilter/issues/11)


3. Demo 2

- More modern tool [https://github.com/tungtv202/go_jwt_revoker.git](https://github.com/tungtv202/go_jwt_revoker.git)
    - Receive JWTK Token
    - Claim `sid` value
    - Add `sid` to bloomfilter
    - NO UI
- Still fail: `error on adding bloomfilter: connection is shut down` 
