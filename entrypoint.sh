#!/bin/bash

# display runner log
docker logs -f gitlab-runner &

# https://docs.travis-ci.com/user/customizing-the-build#Build-Timeouts
max_duration=$((45 * 60))
starting_time=$(date +%s)
ending_time=$(($starting_time + $max_duration))

echo -n "Waiting for restart"
while [[ $(date +%s) -lt $ending_time ]];
do
  # some kind of output is required otherwise
  # travis will cancel the job earlier
  echo -n "."
  sleep 10
done

if [[ "$travistoken" != "" ]]; then
 encoded_slug=$(echo $TRAVIS_REPO_SLUG |sed 's/\//%2F/g')
 # start a rebuild again
 curl -s -X POST \
   -H "Content-Type: application/json" \
   -H "Accept: application/json" \
   -H "Travis-API-Version: 3" \
   -H "Authorization: token $travistoken" \
   -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\"}}" \
   https://api.travis-ci.org/repo/${encoded_slug}/requests
fi
