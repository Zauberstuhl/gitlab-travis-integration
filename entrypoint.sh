#!/bin/bash

if [[ "$1" == "WORKER" ]]; then
  echo -n "Executing worker" && bash worker.sh $2
else
  echo -n "Executing agent" && bash agent.sh
fi
