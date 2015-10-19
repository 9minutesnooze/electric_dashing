#!/usr/bin/env bash

set -e

DOCKER_MACHINE_NAME=default
PORTS="3030 8080"

if [[ $(docker-machine status "$DOCKER_MACHINE_NAME") = "Stopped" ]]; then
  docker-machine start "$DOCKER_MACHINE_NAME"
fi

eval $(docker-machine env "$DOCKER_MACHINE_NAME")

for PORT in $PORTS; do
  if VBoxManage showvminfo "$DOCKER_MACHINE_NAME" --machinereadable | grep -q "tcp-port$PORT"; then
    echo "Port $PORT already mapped"
  else
    echo "Mapping $PORT..."
    VBoxManage controlvm default natpf1 "tcp-port$PORT,tcp,,$PORT,,$PORT"
  fi
done

exec ./docker_run.sh
