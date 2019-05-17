DATE=$(date +%F)
cd /home/deploy/logs/web
ls | grep -v '.gz' > temp
FILE_LOG=$(grep $DATE temp)
echo $FILE_LOG
tailf $FILE_LOG

