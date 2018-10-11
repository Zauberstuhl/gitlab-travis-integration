#!/bin/bash

# https://docs.travis-ci.com/user/customizing-the-build#Build-Timeouts
max_duration=$((45 * 60))
starting_time=$(date +%s)
ending_time=$(($starting_time + $max_duration))
travis_config='"config":{"env":{"matrix":["WORKER=true"]}}'
encoded_slug=$(echo $TRAVIS_REPO_SLUG |sed 's/\//%2F/g')

function check_gitlab() {
  page=0
  api=${gitlaburl}/api/v4
  header="Private-Token: $gitlabauthtoken"
  while true; do
    project_cnt=0
    for id in $(curl -s "$api/projects?page=$page" | jq '.[].id'); do
      # some kind of output is required otherwise
      # travis will cancel the job earlier
      echo -n "."
      api_jobs="$api/projects/$id/jobs?scope=pending"
      pending=$(curl -s --header "$header" "$api_jobs" | jq '.[]')
      if [[ "$pending" != "" ]]; then
        echo "Found one pending job!"
        return 1
      fi
      project_cnt=$(( $project_cnt + 1 ))
    done
    if [ $project_cnt -eq 0 ]; then
      echo "Project count zero ($project_cnt)! Skipping.."
      return 0
    fi
    page=$(( $page + 1 ))
  done
  return 0
}

if [[ "$WORKER" == "true" ]]; then
  docker pull gitlab/gitlab-runner:latest
  docker run --name gitlab-runner --privileged \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v "$(pwd)/config:/etc/gitlab-runner" \
    -d gitlab/gitlab-runner:latest
  sed -i "s#TOKEN#${gitlabtoken}#" config/config.toml
  sed -i "s#URL#${gitlaburl}#" config/config.toml

  echo -n "Waiting for succeed"
  while true; do
    started=$(docker logs gitlab-runner |grep '... received' |wc -l)
    finished=$(docker logs gitlab-runner |grep 'Job succeeded' |wc -l)
    if [ $started -eq $finished ] && [ $started -ne 0 ]; then break; fi
    echo -n "."
  done
else
  echo -n "Waiting for worker"
  while [[ $(date +%s) -lt $ending_time ]];
  do
    result=$(check_gitlab)
    if [ $result -eq 1 ]; then
      # start worker process
      curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Travis-API-Version: 3" \
        -H "Authorization: token $travistoken" \
        -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\",$travis_config}}" \
        https://api.travis-ci.org/repo/${encoded_slug}/requests
    fi
    sleep 60
  done
  # restart agent process
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Travis-API-Version: 3" \
    -H "Authorization: token $travistoken" \
    -d "{\"request\": {\"branch\":\"${TRAVIS_BRANCH}\"}}" \
    https://api.travis-ci.org/repo/${encoded_slug}/requests
fi
