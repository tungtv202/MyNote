dkp() {
    local targetPort=$1
    local result=$(docker ps --format "{{.Ports}}" | grep ${targetPort} | cut -d':' -f2 | cut -d'-' -f1)

    if [ -n "$result" ]; then
        echo $result
    else
        echo "No container found with port $targetPort mapping"
    fi
}

portForward() {
    PORT=$1
    TARGET_PORT=$2

    # Check if the specified port is in use
    if sudo lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
        # Port is in use, find the process and kill it
        echo "Stopping process using port $PORT"
        sudo fuser -k -n tcp $PORT
    fi

    # Start socat to forward traffic
    sudo socat TCP-LISTEN:$PORT,fork TCP:localhost:$TARGET_PORT
}

dkpf() {
    # Get port mapping for the specified port
    portMappingResult=$(dkp $1)

    # Check if the port mapping result is not empty
    if [ -n "$portMappingResult" ]; then
        # Extract the target port from the mapping result
        targetPort=$(echo $portMappingResult | awk '{print $NF}')

        portForward $1 $targetPort
    else
        echo "Error: Port $1 is not mapped to any container."
    fi
}