# Guide hướng dẫn tạo tài khoản và add sshkey 
## 1. Server
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
