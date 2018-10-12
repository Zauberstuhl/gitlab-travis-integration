#!/bin/bash

# https://docs.travis-ci.com/user/customizing-the-build#Build-Timeouts
max_duration=$((45 * 60))
starting_time=$(date +%s)
ending_time=$(($starting_time + $max_duration))
travis_config='"config":{"script":"bash entrypoint.sh WORKER"}'
encoded_slug=$(echo $TRAVIS_REPO_SLUG |sed 's/\//%2F/g')

function check_gitlab() {
  page=0
  api=${gitlaburl}/api/v4
  header="Private-Token: $gitlabauthtoken"
  while true; do
    project_cnt=0
    for id in $(curl -s "$api/projects?page=$page" | jq '.[].id'); do
      api_jobs="$api/projects/$id/jobs?scope=pending"
      pending=$(curl -s --header "$header" "$api_jobs" | jq '.[]')
      if [[ "$pending" != "" ]] && [[ ! -f /tmp/gti.${id}.lock ]]; then
        # lock this project for the next five minutes
        touch /tmp/gti.${id}.lock
        { sleep 300 && rm /tmp/gti.${id}.lock }&
        # return true and start the worker
        echo 1
        return
      fi
      project_cnt=$(( $project_cnt + 1 ))
    done
    if [ $project_cnt -eq 0 ]; then
      echo 0
      return
    fi
    page=$(( $page + 1 ))
  done
  echo 0
  return
}

while [[ $(date +%s) -lt $ending_time ]];
do
  if [ $(check_gitlab) -eq 1 ]; then
    # start worker process
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "Travis-API-Version: 3" \
      -H "Authorization: token $travistoken" \
      -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\",$travis_config}}" \
      https://api.travis-ci.org/repo/${encoded_slug}/requests
  fi
  # some kind of output is required otherwise
  # travis will cancel the job earlier
  echo -n "."
  sleep 10
done

# restart agent process
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $travistoken" \
  -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\"}}" \
  https://api.travis-ci.org/repo/${encoded_slug}/requests
