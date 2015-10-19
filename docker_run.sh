#!/bin/bash

CONTAINERNAME=electric_dashing
IMAGE_NAME="aaronbbrown/electric_dashing"
# Config URLs come from config/config.sh
source "config/config.sh"

source "dm_run.sh"

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
           -e "EGAUGE_URL=$EGAUGE_URL" \
           -e "DB_URL=$DB_URL"\
           --rm -it --name "$CONTAINERNAME" "$IMAGE_NAME"
