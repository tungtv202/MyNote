<!-- TOC -->

- [1. Install](#1-install)
- [2. Một số lệnh Docker](#2-một-số-lệnh-docker)
    - [2.1 Tạo/ Chạy container](#21-tạo-chạy-container)
    - [2.2 Ít dùng](#22-ít-dùng)
- [3 Docker Swarm](#3-docker-swarm)
    - [3.1 Tạo Swarm](#31-tạo-swarm)
    - [3.2 Tạo service](#32-tạo-service)

<!-- /TOC -->
## 1. Install   
- Sau khi cài đặt docker, cần lưu ý gán quyền user cho docker. Nếu không gán quyền, thì command trong docker sẽ bị permission
```sh
sudo usermod -aG dockker $USER
```
Logout sau đó login lại để có hiệu lực
- docker và docker-compose là 2 package khác nhau. Nếu muốn xài docker-compose thì phải cài đặt riêng
- Docker Machine là 1 package riêng, để sử dụng docker machine để tạo các máy ảo trên ubuntu, thì cần cài đặt riêng. Và phải cài đặt "virtual box" trước đó.


## 2. Một số lệnh Docker 
- Kiểm tra phiên bản Docker 
```
docker --version
```
hoặc muốn show chi tiết hơn
```
docker info
```
- Liệt kê các image

``` 
docker images -a
```
// bỏ param -a đi thì sẽ chỉ show image đang run    
- Tải về 1 image từ hub.docker.com
```
docker pull nameimage:tag
```

- Liệt kê các container đang chạy
```
docker ps
```
- Liệt kê tất cả các container 
```
docker ps -a
```
### 2.1 Tạo/ Chạy container 
- Tạo, chạy một container từ image với id (name) là image_id
```
docker run -it --name nameyourcontainer -h "nameyourhost" image_id
```
Một số tham số thêm vào khi tạo container:
- Ánh xạ thư mục máy host vào container
```
-v path-in-host:path-in-container
```
- Nhận chia sẻ thư mục đã ánh xạ từ container khác
```
--volumes-from other-container-name
```
- Container có cổng ngoài public-port ánh xạ vào cổng trong target-port
```
-p public-port:target-port
```
- Thiết lập để Docker tự khởi động container
```
--restart=always
```
- Vào terminal container đang chạy
```
docker container attach containerid
```
- chạy một lệnh command trên container đang hoạt động
```
docker exec -it containerid command
```
- Dừng hoạt động một container
```
docker stop containerid
```
- Chạy một container
```
docker start -i containerid
```
- Khởi động lại container
```
docker restart containerid
```
- Xóa container
```
docker rm containerid
```
- Thoát -it terminal nhưng container vẫn chạy
```
CTRL +P, CTRL + Q
```

- Cách để copy file cấu hình trong docker 
```
docker run --rm -v /mycode/swarm/:/home/ httpd:latest cp /usr/local/apache2/conf/httpd.conf /home/httpd.conf
```


### 2.2 Ít dùng
- Lưu một container đang dừng thành Image
```
docker commit containerid imagename:imageversion
```
- Lưu image ra đĩa
```
docker save --output myimage.tar myimage_id
```
- Nạp Image trên đĩa vào Docker
```
docker load -i myimage.tar
```
- Đổi tên Image
```
docker tag image_id imagename:version
```
- Liệt kê các network
```
docker network ls
```
- Tạo mạng kiểu bridge đặt tên là name-network
```
docker network create --driver bridge name-network
```
- Nối container vào mạng name-network
```
docker network connect name-network name-container
```
- Lấy thông tin về image hoặc container
```
docker inspect name_or_id_of_image_container
```
- Lấy thông lịch sử tạo thành iamge
```
docker history name_or_id_of_image
```
- Theo dõi thay đổi các file trên container
```
docker diff container-name-or-id
```
- Đọc log container
```
docker logs -f container-name-or-id
```
- Đo lường thông tin
```
docker stats container-name-or-id
```

## 3 Docker Swarm
### 3.1 Tạo Swarm
- Tại node leader > khởi tạo
```
docker swarm init --advertise-addr=192.168.99.117
```
- Tại node worker > join
```
docker swarm join --token SWMTKN-1-5xv7z2ijle1dhivalkl5cnwhoadp6h8ae0p7bs5tmanvkpbi3l-5ib6sjrd3w0wdhfsnt8ga7ybd 192.168.99.111:2377
```
- Checking node
```
docker node ls
```
### 3.2 Tạo service
- Command example
```bash
docker service create --replicas 5 -p 8085:8085 --name testservice ichte/swarmtest:node
```
```bash
# Liệt kê các service trên swarm
docker service ls

# Liệt kê các container cho dịch vụ có tên testservice
docker service ps testservice

# Kiểm tra log cho dịch vụ testservice
docker service logs testservice

# Scale - thay đổi số container cho dịch vụ testservice đang chạy thành n (1, 2, 3 ...) container
docker service scale testservice=n

# Cập nhật thiết lập cho dịch vụ testservice đang chạy
# - Thay đổi Image
docker service update --image=ichte/swarmtest:php testservice
# - Thay đổi tài nguyên CPU, MEM
docker service update --limit-cpu="0.5"  --limit-memory=150MB testservice
# - Các cập nhật khác update service

# Xóa dịch vụ testservice
docker service rm servicename
```
