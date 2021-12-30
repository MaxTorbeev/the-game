#!/bin/bash

. ./helpers.sh --source-only

# set exit on any error
set -e

# log file
logfile="${rootpath}/scripts/.git-merge.log"

try
(
  currentBranch=$( git symbolic-ref --short HEAD )

  echo "Current branch $currentBranch with hash $( git rev-parse --short HEAD )"
  echo "======="

  # checkout to branch
  git checkout "$branch" -q >> $logfile
  # and update branch from repo
  git pull "$repo" "$branch" -q >> $logfile

  # check conflict via git merge-tree
  isConflict="$(git merge-tree "$(git merge-base $currentBranch "$branch")" "$branch" $currentBranch | sed -ne '/^\+<<</,/^\+>>>/ p')"

  if [ -n "$isConflict" ]; then
    echo "Conflict: ";
    echo "$isConflict";
#    echo "======="
#    git checkout "$currentBranch" >/dev/null 2>&1 ;
  else
    git checkout "$currentBranch" -q >> $logfile && git merge "$repo"/"$branch" -q >> $logfile
    echo "Release has been merged to $currentBranch"
  fi
)
catch || {
  echo "Abort!"
  echo "return with code: $ex_code"
}
