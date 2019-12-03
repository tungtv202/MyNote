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
