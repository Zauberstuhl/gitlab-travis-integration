#!/bin/bash

while true; do
  # some kind of output is required otherwise
  # travis will cancel the job earlier
  echo -n "."
  sleep 1
done &

# configure runner
sed -i "s#TOKEN#${gitlabtoken}#" config/config.toml
sed -i "s#URL#${gitlaburl}#" config/config.toml

# start runner
docker pull gitlab/gitlab-runner:latest
docker run --name gitlab-runner --privileged \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "$(pwd)/config:/etc/gitlab-runner" \
  -d gitlab/gitlab-runner:latest

# https://docs.travis-ci.com/user/customizing-the-build#Build-Timeouts
sleep $(( 45 * 60 ))

# restart process
encoded_slug=$(echo $TRAVIS_REPO_SLUG |sed 's/\//%2F/g')
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $travistoken" \
  -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\"}}" \
  https://api.travis-ci.org/repo/${encoded_slug}/requests

exit 0
