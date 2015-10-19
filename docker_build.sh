#!/bin/bash

IMAGE_NAME="aaronbbrown/electric_dashing"
docker build -t "$IMAGE_NAME" $(dirname $0)
docker push "$IMAGE_NAME"
