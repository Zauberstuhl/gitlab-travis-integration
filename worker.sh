#!/bin/bash

sed -i "s#TOKEN#${gitlabtoken}#" config/config.toml
sed -i "s#URL#${gitlaburl}#" config/config.toml

docker pull gitlab/gitlab-runner:latest
docker run --name gitlab-runner --privileged \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "$(pwd)/config:/etc/gitlab-runner" \
  -d gitlab/gitlab-runner:latest

# https://docs.travis-ci.com/user/customizing-the-build#Build-Timeouts
sleep $(( 45 * 60 ))
