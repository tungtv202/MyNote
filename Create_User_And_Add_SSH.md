# Guide hướng dẫn tạo tài khoản và add sshkey 
## 1. Server
Create Home Directory + .ssh Directory
```shell
mkdir -p /home/mynewuser/.ssh
```


Create Authorized Keys File
```shell
touch /home/mynewuser/.ssh/authorized_keys
```

Create User + Set Home Directory
```shell
useradd -d /home/mynewuser mynewuser
```

Add User to sudo Group
```shell
usermod -aG sudo mynewuser
``` 


Set Permissions
```shell
chown -R mynewuser:mynewuser /home/mynewuser/
chown root:root /home/mynewuser
chmod 700 /home/mynewuser/.ssh
chmod 644 /home/mynewuser/.ssh/authorized_keys
```

## 2. Client
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
