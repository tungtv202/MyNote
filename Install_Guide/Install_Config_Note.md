---
title: Install & Config Note
date: 2020-04-01 18:00:26
tags:
    - note
category: 
    - install_guide
---

# Install & config note

## Selenium ChromeDriver
https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/

## OpenVPN
https://support.hidemyass.com/hc/en-us/articles/202721546-OpenVPN-via-terminal-using-openvpn-binary-the-manual-way-

- [Easy Way to Install and Configure OpenVPN Server on Ubuntu 18.04 / Ubuntu 16.04](https://computingforgeeks.com/easy-way-to-install-and-configure-openvpn-server-on-ubuntu-18-04-ubuntu-16-04/)

## Install PostgreSQL 12 on linux    
https://computingforgeeks.com/install-postgresql-12-on-ubuntu/

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

## Node, Npm

```bash
$ sudo apt-get install npm
(...apt installation of npm was successful...)
$ npm -v
3.5.2
$ command -v npm
/usr/bin/npm
$ sudo npm install -g npm
(...npm installation of npm was successful...so far, so good)
$ type npm
npm is hashed (/usr/bin/npm)
hash -d npm
$ npm -v
6.4.1
$ command -v npm
/usr/local/bin/npm
```

##  Postgresql

```bash
 docker run --name postgres-crawler1688 \
    -e POSTGRES_PASSWORD=crawler1688a@ \
    -v /home/ubuntu/docker/postgres_data:/var/lib/postgresql/data  \
    -p 5432:5432 \
    -d postgres
```

###  pgadmin4 (webui cho postgresql)

```bash
docker run -p 8083:80 \
    -e 'PGADMIN_DEFAULT_EMAIL=admin' \
    -e 'PGADMIN_DEFAULT_PASSWORD=password@' \
    -d dpage/pgadmin4
```
###  install psql client

```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt-get install postgresql-client
pg_dump -h crawler1688-s2.tungexplorer.me -U postgres -d crawler1688  --exclude-table=exclude_id_seq > backup_crawler1688_`date +%Y_%m_%d`.sql
```

## Prometheus

- prometheus_example.yml

```yaml
# my global config
global:
  scrape_interval:     1s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 5s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
# - "first_rules.yml"
# - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ['localhost:9090']
```

## Java

- Download package

```bash
wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz
wget https://download.oracle.com/otn/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.tar.gz?AuthParam=1586232610_d9b5e1b404c1d80ee03b9ad36c391ed6
```

- Extract

```bash
tar zxvf openjdk-11.0.2_linux-x64_bin.tar.gz
```

```bash
sudo mv jdk-11* /usr/local/
```
- Set environment variables

```bash
sudo nano /etc/profile.d/jdk.sh
```
- Add 

```bash
export JAVA_HOME=/usr/local/jdk-11.0.2
export PATH=$PATH:$JAVA_HOME/bin
```

- Can set JAVA_HOME, PATH env in:

```
/etc/environment
```
or 
```
~/.basrhc
```
or new file in `/etc/profile.d/`

```
/etc/profile.d/jdk.sh
```
Source env when startup OS

```
source $file
```

### Common errors
- Should append PATH (not replace)

// Sưu tầm: https://computingforgeeks.com/how-to-install-java-11-on-ubuntu-18-04-16-04-debian-9

### Intellij

```
- File > Project Structure > Platform Settings > SDKs 
  - Click button (+) `Add new sdk` > Download JDK 
        - Chọn Vendor và Version > Click Download
```

## SecureCRT

