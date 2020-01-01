# Nohup, create service run background
```json
 giúp command chạy app sẽ luôn được thực thi, ngay cả khi mình ngắt kết nối ssh tới server ho close window
```
- Tạo file service bất kỳ trong `cd /etc/init.d/`
- Ex `nano myservice`
- key:
```
nohup java -jar -Dspring.profiles.active=test $PATH_TO_JAR  >> $LOG_DIR 2>&1&
```

- full:
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