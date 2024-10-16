---
title: Install & Config Note
date: 2020-04-01 18:00:26
updated: 2020-04-01 18:00:26
tags:
    - note
category: 
    - install_guide
---

# Install & config note

## Selenium ChromeDriver

https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/

## Aria2

- `aria2`: tool download
- `webui-aria2`: cung cấp giao diện webui cho aria2

1. Install

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

## Postgresql

### install psql client

```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt-get install postgresql-client
pg_dump -h crawler1688-s2.tungexplorer.me -U postgres -d crawler1688  --exclude-table=exclude_id_seq > backup_crawler1688_`date +%Y_%m_%d`.sql
```

## docker-compose_install_kafdrop.yml

```yaml
version: "2"
services:
  kafdrop:
    image: obsidiandynamics/kafdrop
    restart: "no"
    ports:
      - "9009:9000"
    environment:
      KAFKA_BROKERCONNECT: "tungexplorer.me:9092" 
```

## Install Node js http server

```bash
docker run --name file-server -p 8082:8080 -v /home/ubuntu/torrents:/torrents -w /torrents -t cannin/nodejs-http-server
```

### Install qbittorrent

```bash
docker run -d -v /home/ubuntu/torrents:/downloads -p 9998:8080 --name torrent linuxserver/qbittorrent
# account: admin/adminadmin
```

