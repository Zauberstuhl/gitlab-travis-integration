#!/bin/bash

sed -i "s#TOKEN#${gitlabtoken}#" config/config.toml
sed -i "s#URL#${gitlaburl}#" config/config.toml

docker pull gitlab/gitlab-runner:latest
docker run --name gitlab-runner --privileged \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "$(pwd)/config:/etc/gitlab-runner" \
  -d gitlab/gitlab-runner:latest

while true; do
  started=$(docker logs gitlab-runner 2>&1 |grep 'received' |wc -l)
  finished=$(docker logs gitlab-runner 2>&1 |grep 'Job succeeded' |wc -l)
  if [ $started -eq $finished ] && [ $started -ne 0 ]; then break; fi
  # some kind of output is required otherwise
  # travis will cancel the job earlier
  echo -n "."
  sleep 30
done
