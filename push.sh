#!/usr/bin/env bash

set -e
set -x

source build.sh

docker push "$IMAGE_NAME"
