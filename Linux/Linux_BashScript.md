---
title: Linux - Bash Script Collection
date: 2020-01-22 18:00:26
updated: 2020-01-22 18:00:26
tags:
    - bash
    - script
    - install
category: 
    - linux
---

### Run file after restart os

```bash
# In the file you put in /etc/init.d/ you have to set it executable with
chmod +x /etc/init.d/start_my_app

# if this does not run you have to create a symlink to /etc/rc.d/
ln -s /etc/init.d/start_my_app /etc/rc.d/

# And don't forget to add on top of that file:
#!/bin/sh
```

### Nohup
- Tạo file service bất kỳ trong `cd /etc/init.d/`
- Ex `nano myservice`
- key:
```
nohup java -jar -Dspring.profiles.active=test $PATH_TO_JAR  >> $LOG_DIR 2>&1&
```

```bash
#!/bin/sh
SERVICE_NAME=myservice
PATH_TO_JAR=/home/share/application.jar
LOG_DIR =/home/share/log.txt
PID_PATH_NAME=/tmp/application-pid
case $1 in
   start)
       echo "Starting $SERVICE_NAME ..."
       if [ ! -f $PID_PATH_NAME ]; then
           nohup java -jar -Dspring.profiles.active=test $PATH_TO_JAR  >> $LOG_DIR 2>&1&
           echo $! > $PID_PATH_NAME
           echo "$SERVICE_NAME started ..."
       else
           echo "$SERVICE_NAME is already running ..."
       fi
   ;;
   stop)
       if [ -f $PID_PATH_NAME ]; then
           PID=$(cat $PID_PATH_NAME);
           echo "$SERVICE_NAME stoping ..."
           kill $PID;
           echo "$SERVICE_NAME stopped ..."
           rm $PID_PATH_NAME
       else
           echo "$SERVICE_NAME is not running ..."
       fi
   ;;
   restart)
       if [ -f $PID_PATH_NAME ]; then
           PID=$(cat $PID_PATH_NAME);
           echo "$SERVICE_NAME stopping ...";
           kill $PID;
           echo "$SERVICE_NAME stopped ...";
           rm $PID_PATH_NAME
           echo "$SERVICE_NAME starting ..."
           nohup java -jar -Dspring.profiles.active=test $PATH_TO_JAR >> $LOG_DIR 2>&1&
           echo $! > $PID_PATH_NAME
           echo "$SERVICE_NAME started ..."
       else
           echo "$SERVICE_NAME is not running ..."
       fi
   ;;
esac 
```
- SERVICE_NAME => tên của service, đặt tùy thích, lúc xem monitor các process của ubuntu, tên cái service này nó sẽ hiển thị
- PATH_TO_JAR => đường dẫn trỏ tới file .jar cần chạy
- LOG_DIR => đường dẫn tới chỗ để ghi log lại
- PID_PATH_NAME => đánh dấu cái pid (mã ID process cái service), mục đích để khi gõ command stop, nó sẽ sử dụng cái pid đó để kill process.

### Create User and add sshkey 
#### 1. Server
Create Home Directory + .ssh Directory
```shell
mkdir -p /home/deploy/.ssh
```
Create Authorized Keys File
```shell
touch /home/deploy/.ssh/authorized_keys
```

Create User + Set Home Directory
```shell
useradd -d /home/deploy deploy
```

Add User to sudo Group
```shell
usermod -aG sudo deploy
``` 

Set Permissions

```shell
chown -R deploy:deploy /home/deploy/
chown root:root /home/deploy
chmod 700 /home/deploy/.ssh
chmod 644 /home/deploy/.ssh/authorized_keys
```

#### 2. Client
For example, to generate an RSA key, I'd use:

```shell
ssh-keygen -a 1000 -b 4096 -C "" -E sha256 -o -t rsa
```
Get ssh key

```shell
cat ~/.ssh/id_rsa.pub
```
Paste sshkey to server

```shell
/home/mynewuser/.ssh/authorized_keys
```

### Get Public IP

```bash
dig +short myip.opendns.com @resolver1.opendns.com
```
### kill process by port
```bash
wget https://raw.github.com/abdennour/miscs.sh/master/killport
killport 3000
```

### check port running

```bash
sudo netstat -lnp
```

### show size directory, "MB"

```bash
alias ls="ls --block-size=M"
```

### Show log script

```bash
DATE=$(date +%F)
cd /home/deploy/logs/web
ls | grep -v '.gz' >temp
FILE_LOG=$(grep $DATE temp)
echo $FILE_LOG
tailf $FILE_LOG
```

### Set icon desktop for anyapp
- `cd /usr/share/applications`
- `sudo gedit outline.desktop`
```
[Desktop Entry]
Name=Outline
Comment=Outline VPN
Exec="/home/tungtv/Downloads/opt/Outline-Client.AppImage" %U
Terminal=false
Type=Application
Icon=/home/tungtv/Pictures/icon/outline.png
StartupWMClass=Outline
Categories=Utility;
```
- sudo updatedb