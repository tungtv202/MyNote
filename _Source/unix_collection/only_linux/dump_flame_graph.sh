#!/bin/bash
echo "Try to download async-profiler-2.0-linux-x64"
ASYNC_PROFILER=async-profiler-2.0-linux-x64
wget https://github.com/jvm-profiling-tools/async-profiler/releases/download/v2.0/$ASYNC_PROFILER.tar.gz
tar xvf async-profiler-2.0-linux-x64.tar.gz

cd $ASYNC_PROFILER || exit

FILE_NAME_SUFFIX=$(date '+%Y_%m_%d-%H_%M')
DURATION=600
if [ -z "$1" ]; then
    DURATION=600
else
    DURATION=$1
fi

echo "Try to dump CPU in $DURATION seconds. Output file: /tmp/flame_graph_CPU_$FILE_NAME_SUFFIX.html"
./profiler.sh -d $DURATION -f /tmp/flame_graph_CPU_$FILE_NAME_SUFFIX.html -e itimer 1


echo "Try to dump MEMORY in $DURATION seconds. Output file: /tmp/flame_graph_MEMORY_$FILE_NAME_SUFFIX.html"
./profiler.sh -d $DURATION -f /tmp/flame_graph_MEMORY_$FILE_NAME_SUFFIX.html --alloc 500k 1


