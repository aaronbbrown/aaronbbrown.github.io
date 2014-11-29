#!/usr/bin/env bash

IMAGE_NAME="aaronbbrown/blog"

set -x
set -e

bundle install
bundle exec jekyll build

docker build -t "$IMAGE_NAME" .
