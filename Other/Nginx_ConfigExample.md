---
title: Nginx - Config exmaple
date: 2019-02-11 18:00:26
tags:
    - nginx
    - template
category: 
    - other
---

# Tổng hợp các file cấu hình NGINX mẫu
- File cấu hình mỗi site đặt tại `/etc/nginx/sites-enabled`
### 1. File normal

```bash
# /etc/nginx/sites-enabled/getlink.tungexplorer.me
server {
  listen 80;
  server_name getlink.tungexplorer.me;

  location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;

        proxy_set_header Origin '';
  }
}
```
### 2. File có basic authen
- setting basic authen

```bash
# 1
sudo apt-get install apache2-utils

# 2
sudo htpasswd -c /etc/nginx/.htpasswd nginx

# 3, verify
cat /etc/nginx/.htpasswd
```
- file server

```bash
server {
  listen 80;
  server_name file.tungexplorer.me;
  access_log off;
  auth_basic            "Restricted Access!";
  auth_basic_user_file  /etc/nginx/conf.d/.htpasswd;

  location / {
    proxy_pass http://127.0.0.1:8082;
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_redirect     off;

    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;
  }
}
```

### 3. File regex

```
server {
  listen 80;
  server_name   ~^(www\.)?[^.]+.tungexplorer.me$;
  access_log off;
  if ($host ~* ^(www\.)?([^.]+).tungexplorer.me$) {
    set $subdomain $2;
  }
  resolver 8.8.8.8 valid=10s;
  location / {
    proxy_pass http://$subdomain.fshare.vn;
    proxy_read_timeout 300;
    proxy_connect_timeout 300;
    proxy_redirect     off;

    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_set_header   X-Real-IP         $remote_addr;
  }
}
```   
