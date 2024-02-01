dockerPort() {
    local targetPort=$1
    local result=$(docker ps --format "{{.Ports}}" | grep ${targetPort} | cut -d':' -f2 | cut -d'-' -f1)

    if [ -n "$result" ]; then
        echo $result
    else
        echo "No container found with port $targetPort mapping"
    fi
}