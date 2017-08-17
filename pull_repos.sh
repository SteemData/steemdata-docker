#!/bin/bash

repos=("steemdata-api" "steemdata-mongo" "steemdata.com" "steemdata-webapi")
for repo in "${repos[@]}"
do
  echo "$repo:"
  if [ -d "./$repo" ]; then
    cd $repo && git pull origin master && cd ..
  else
    git clone "git@github.com:SteemData/$repo.git"
  fi
done
