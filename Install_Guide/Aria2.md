## Aria2 - tool hỗ trợ download trên server 
- `aria2`: tool download
- `webui-aria2`: cung cấp giao diện webui cho aria2

### 1. Install 
ref: https://hub.docker.com/r/timonier/webui-aria2
- install `aria2`
```bash
# Define installation folder

export INSTALL_DIRECTORY=/usr/bin

# Use local installation
sudo bin/installer install

# Use remote installation
curl --location "https://gitlab.com/timonier/aria2/raw/master/bin/installer" | sudo sh -s -- install

# See all aria2c options

aria2c --help
```
- run aria2
```bash
# 1. plain
aria2c --dir /home/ubuntu/torrents --enable-rpc --rpc-listen-all
# 2. dùng nohup
nohup  aria2c --dir /home/ubuntu/torrents --enable-rpc --rpc-listen-all >> /tmp/aria2c.log 2>&1&
# chỉnh "/home/ubuntu/torrents" thành đường dẫn mà file sau khi download sẽ được lưu vào
# lưu ý sau khi run, thì 1 container docker mới sẽ được chạy
```
- install `webui-aria2`
```bash
docker run -d -p 9999:80 timonier/webui-aria2
```