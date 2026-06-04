#!/usr/bin/env zsh

# Docker shell helpers sourced by 1_my_bash.sh.

# Stop the current Docker Compose project and remove volumes/orphans.
# Example: dcd
alias dcd="docker compose down -v --remove-orphans"

# Start the current Docker Compose project in detached mode.
# Example: dcu
alias dcu="docker compose up -d"

# Remove dangling Docker images older than the given age.
# Default: 1440h means 60 days.
# Examples: docker_prune_old_dangling_images, docker_prune_old_dangling_images 720h
docker_prune_old_dangling_images() {
  local age="${1:-1440h}"

  if [[ "$age" == "-h" || "$age" == "--help" ]]; then
    echo "Usage: docker_prune_old_dangling_images [age]"
    echo "Example: docker_prune_old_dangling_images 720h"
    return 0
  fi

  docker image prune --force --filter "until=$age"
}

# Build and push the tmail-backend-distributed Docker image with Maven Jib.
# Examples: mvn_docker, mvn_docker 0604.1530
mvn_docker() {
  local tag="${1:-$(date '+%m%d.%H%M')}"
  echo "Maven compile and build+push docker tungtv202/tmail-backend-distributed:$tag"
  mvn compile -DskipTests -Djib.to.image="tungtv202/tmail-backend-distributed:$tag" jib:build
}

# Return the host port mapped to a Docker container port.
# Example: docker_port 8080
docker_port() {
  local target_port="$1"
  local result

  if [[ -z "$target_port" ]]; then
    echo "Usage: docker_port <container-port>" >&2
    return 1
  fi

  result="$(
    docker ps --format '{{.Ports}}' |
      tr ',' '\n' |
      awk -v target="$target_port" '
        index($0, "->" target "/") {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
          split($0, parts, "->")
          host = parts[1]
          sub(/.*:/, "", host)
          print host
          exit
        }
      '
  )"

  if [[ -n "$result" ]]; then
    echo "$result"
  else
    echo "docker_port: no container found with container port $target_port mapping" >&2
    return 1
  fi
}

# Short alias function for docker_port.
# Example: dkp 8080
dkp() {
  docker_port "$@"
}

# Forward a local port to another local target port.
# Example: port_forward 8080 32768
port_forward() {
  local port="$1"
  local target_port="$2"
  local pids

  if [[ -z "$port" || -z "$target_port" ]]; then
    echo "Usage: port_forward <local-port> <target-port>" >&2
    return 1
  fi

  pids="$(sudo lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null)"
  if [[ -n "$pids" ]]; then
    echo "Stopping process using port $port"
    echo "$pids" | xargs sudo kill
  fi

  sudo socat TCP-LISTEN:"$port",fork TCP:localhost:"$target_port"
}

# Forward a local port to the Docker host port mapped from the same container port.
# Example: dkpf 8080
dkpf() {
  local port="$1"
  local target_port

  if [[ -z "$port" ]]; then
    echo "Usage: dkpf <container-port>" >&2
    return 1
  fi

  target_port="$(docker_port "$port")" || return 1
  port_forward "$port" "$target_port"
}
