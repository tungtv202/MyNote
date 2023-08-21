#!/bin/bash

file="hash_commit"
# Use the while loop to read and echo each line from the file
while IFS= read -r line; do
  start_time=$(date +%s)

  echo "Start $line"
  git checkout $line
  git submodule update
  mvn clean install -Dmaven.javadoc.skip=true -DskipTests -T15 > logs/$line.txt
  cd /home/tungtv/workplace/JAMES/tmail-backend/tmail-backend/apps/distributed
  mvn clean install jib:build -Dmaven.javadoc.skip=true -DskipTests  -Djib.to.image=vttran1/tmail-backend-distributed:$line -T7
  cd /home/tungtv/workplace/JAMES/tmail-backend/
  echo "Done $line"

  end_time=$(date +%s)
  duration=$((end_time - start_time))
  hours=$((duration / 3600))
  minutes=$(( (duration % 3600) / 60 ))
  seconds=$((duration % 60))
  duration_formatted=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)

  echo "$line $duration_formatted" >> time.txt
  bash /home/tungtv/workplace/MyNote/_Source/linux_collection/send_noti_via_tele.sh "Done $line $duration_formatted"
done < "$file"



