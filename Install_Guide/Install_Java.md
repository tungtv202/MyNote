# Install JAVA manual
## 1. Lý do cài đặt manual 
Khi cài đặt Java SDK trên Ubuntu, hay bị lỗi không tìm thấy package, No Candidate...

## 2. Install 
- Download file package đã được nén     
Dùng wget, curl...      
Link: https://jdk.java.net/java-se-ri/11 
```bash
wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz
wget https://download.oracle.com/otn/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.tar.gz?AuthParam=1586232610_d9b5e1b404c1d80ee03b9ad36c391ed6

```    
- Giải nén
```bash
tar zxvf openjdk-11.0.2_linux-x64_bin.tar.gz
```
- Move sang 1 folder mới bất kỳ
```bash
sudo mv jdk-11* /usr/local/
```
- Set environment variables
```bash
sudo nano /etc/profile.d/jdk.sh
```
Add 
```
export JAVA_HOME=/usr/local/jdk-11.0.2
export PATH=$PATH:$JAVA_HOME/bin
```
Nếu biến môi trường ko nhận, có thể config biến JAVA_HOME, PATH trong file 
```
/etc/environment
```
hoặc 
```
~/.basrhc
```
hoặc tạo file mới trong folder /etc/profile.d/
```
/etc/profile.d/jdk.sh
```
Để khi OS khởi động lại thì tự động lấy biến môi trường
- Source variables để session load lại 
```
source $file
```

## 3. Một số lỗi hay gặp
Lưu ý config PATH, cẩn thận override PATH đang có. Khi đó OS không thể đăng nhập được. 

// Sưu tầm: https://computingforgeeks.com/how-to-install-java-11-on-ubuntu-18-04-16-04-debian-9/?fbclid=IwAR2XkLy8uOKof_9Yt_dxPWp7SDgbueJk0J0BSUslQiiXukfza1SDWAoN5aY