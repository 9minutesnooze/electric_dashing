#!/bin/bash

CONTAINERNAME=electric_dashing
IMAGE_NAME="aaronbbrown/electric_dashing"

# check if the container is running
docker ps | \
  awk '$NF=="'$CONTAINERNAME'" {print $NF}' | \
  grep -q "$CONTAINERNAME" && \
  docker stop "$CONTAINERNAME"

# check if the container exists
docker ps -a | \
  awk '$NF=="'$CONTAINERNAME'" {print $NF}' | \
  grep -q "$CONTAINERNAME" && \
  docker rm -f "$CONTAINERNAME"

# run the container
# assumes local postgres
docker run -p 3030:3030 \
           -e "EGAUGE_URL=http://sol.borg.lan" \
           -e "DB_URL=postgres://aaron@cavil.borg.lan/solar"\
           --rm -it --name "$CONTAINERNAME" "$IMAGE_NAME"
