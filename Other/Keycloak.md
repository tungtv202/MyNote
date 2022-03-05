---
title: Keycloak
date: 2021-12-08 21:00:26
updated: 2021-12-08 18:00:26
tags:
    - sso
    - oidc
    - id provider
category: 
    - other
---

# Keycloak 

## Quick start 

```bash
docker run -p 8080:8080 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin quay.io/keycloak/keycloak:latest
```

[http://localhost:8080/auth/admin/](http://localhost:8080/auth/admin/)

## Note
### Realm
- Master realm: this realm was created for you when you first started Keycloak, It contains the admin
account you created at the first login. You use this realm only to create other realms
- Other realms: these realms are created by the admin in the master realm. In these realms, administrators
create users and applications. The applications are owned by the users.

### Access Type (oidc)
- confidental = basic authorization_code (Need `client_secret`)
- public = PKCE (when SPA like reactjs app)

### Use case
- Keycloak vs Krakend
    - SHOULD WE ASSIGN AUTHENTICATION DUTY TO API GATEWAY?
    - SHOULD WE USE KEYCLOAK LIKE AS AUTHORIZATION SEVER IN "INTERNAL" SYSTEM LIKE AS MICROSERVICE?