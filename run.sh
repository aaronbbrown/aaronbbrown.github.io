#!/usr/bin/env bash

set -e
set -x

LOCALPORT=8080
B2DIP=$(boot2docker ip 2>/dev/null)
#B2DURL="http://${B2DIP}:2376"
CONTAINERNAME="temp_9ms_blog"

source build.sh

# check if the container is running
docker ps | awk '$NF=="'$CONTAINERNAME'" {print $NF}' | grep -q $CONTAINERNAME && docker stop "$CONTAINERNAME"

# check if the container exists
docker ps -a | awk '$NF=="'$CONTAINERNAME'" {print $NF}' | grep -q $CONTAINERNAME && docker rm -f "$CONTAINERNAME" 

docker run --name "$CONTAINERNAME" -p ${LOCALPORT}:80 -d aaronbbrown/blog

BLOG_URL="http://${B2DIP}:${LOCALPORT}"
open "$BLOG_URL"
