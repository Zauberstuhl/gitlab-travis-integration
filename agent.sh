#!/bin/bash

travis_config='"config":{"script":"bash entrypoint.sh WORKER"}'
encoded_slug=$(echo $TRAVIS_REPO_SLUG |sed 's/\//%2F/g')

while true; do
  # some kind of output is required otherwise
  # travis will cancel the job earlier
  echo -n "."
  sleep 1
done &

# start worker process
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $travistoken" \
  -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\",$travis_config}}" \
  https://api.travis-ci.org/repo/${encoded_slug}/requests

# https://docs.travis-ci.com/user/customizing-the-build#Build-Timeouts
sleep $(( 45 * 60 ))

# restart agent process
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $travistoken" \
  -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\"}}" \
  https://api.travis-ci.org/repo/${encoded_slug}/requests

exit 0
