#!/bin/bash

# install curl dependency
apt-get update && apt-get install -y curl

# download runner
curl -Lo /usr/local/bin/gitlab-runner \
  https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
chmod +x /usr/local/bin/gitlab-runner

log=$(mktemp)
gitlab-runner run-single --name travis-ci \
  -u "$gitlaburl" -t "$gitlabtoken" \
  --executor shell --shell bash > $log 2>&1 &

while true; do
  started=$(cat $log |grep received |wc -l)
  finished=$(cat $log |egrep 'Job (failed|succeeded)' |wc -l)
  if [ $started -eq $finished ] && [ $started -ne 0 ]; then break; fi
  # some kind of output is required otherwise
  # travis will cancel the job earlier
  echo "(started:$started finished:$finished)"
  sleep 30
done
