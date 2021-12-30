#!/bin/bash

. ./helpers.sh --source-only

# set exit on any error
set -e

# log file
logfile="${rootpath}/scripts/.git-merge.log"

try
(
  currentBranch=$( git symbolic-ref --short HEAD )
  currentHead=$( git rev-parse --short HEAD )

  echo "Current branch $currentBranch with hash $currentHead"
  echo "======="

  git checkout release -q >> $logfile && git pull origin release -q >> $logfile

  isConflict="$(git merge-tree "$(git merge-base $currentBranch release)" release $currentBranch | sed -ne '/^\+<<</,/^\+>>>/ p')"

  if [ -n "$isConflict" ]; then
    echo "Conflict: ";
    echo "$isConflict";
    echo "======="
    git checkout "$currentBranch"
    exit 1;
  else
    git checkout "$currentBranch" -q >> $logfile && git merge origin/release -q >> $logfile
    echo "Release has been merged to $currentBranch"
  fi
)
catch || {
  echo $ex_code
}
