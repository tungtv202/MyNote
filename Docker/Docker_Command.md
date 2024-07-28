---
title: Docker - Command
date: 2019-12-03 18:00:26
updated: 2019-12-03 18:00:26
tags:
    - docker
    - command
    - script
    - install
category: 
    - docker
---

## 1. Install

```bash 
#!/bin/bash

# Set Docker version (you can modify this as needed)
DOCKER_VERSION=24.0.7
# Install Docker
echo "Try to build with Docker version: $DOCKER_VERSION"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh --version $DOCKER_VERSION
```
- Sau khi cài đặt docker, cần lưu ý gán quyền user cho docker. Nếu không gán quyền, thì command trong docker sẽ bị
  permission

```sh
sudo usermod -aG docker $USER
```

Logout sau đó login lại để có hiệu lực

## 3 Docker Swarm

### 3.1 Tạo Swarm

```bash
# Tại node leader > khởi tạo
docker swarm init --advertise-addr=192.168.99.117

# Tại node worker > join
docker swarm join --token SWMTKN-1-5xv7z2ijle1dhivalkl5cnwhoadp6h8ae0p7bs5tmanvkpbi3l-5ib6sjrd3w0wdhfsnt8ga7ybd 192.168.99.111:2377

# Kiểm tra các node trong swarm
docker node ls
```

### 3.2 Tạo service

```bash
# Tạo một service
docker service create --replicas 5 -p 8085:8085 --name testservice ichte/swarmtest:node

# Liệt kê các service trên swarm
docker service ls

# Liệt kê các container cho dịch vụ có tên testservice
docker service ps testservice

# Kiểm tra log cho dịch vụ testservice
docker service logs testservice

# Thay đổi số lượng container cho dịch vụ testservice
docker service scale testservice=n

# Cập nhật thiết lập cho dịch vụ testservice
# Thay đổi Image
docker service update --image=ichte/swarmtest:php testservice

# Thay đổi tài nguyên CPU, MEM
docker service update --limit-cpu="0.5" --limit-memory=150M testservice

# Các cập nhật khác cho service
docker service update --update-parallelism=2 --update-delay=10s testservice

# Xóa dịch vụ testservice
docker service rm testservice

# Xóa nhiều Docker images không có tên (dangling images)
docker rmi $(docker images -f "dangling=true" -q)

```