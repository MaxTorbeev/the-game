#!/bin/bash

. ./helpers.sh --source-only

# set exit on any error
set -e

# log file
logfile="${rootpath}/scripts/.git-merge.log"

try
(
  # current branch
  current=$( git symbolic-ref --short HEAD )

  echo "Current branch $current with hash $( git rev-parse --short HEAD )"
  echo "======="

  # checkout to branch
  git checkout "$branch" -q >> $logfile
  # and update branch from repo
  git pull "$repo" "$branch" -q >> $logfile

  # check conflict via git merge-tree
  isConflict="$(git merge-tree "$(git merge-base "$current" "$branch")" "$branch" "$current" | sed -ne '/^\+<<</,/^\+>>>/ p')"

  git merge-tree "$(git merge-base "$current" "$branch")" "$branch" "$current" >> $logfile

  if [ -n "$isConflict" ]; then
    echo "Conflict: ";
    echo "$isConflict";
    echo "======="
    git checkout "$current" >/dev/null 2>&1 ;
  else
    git checkout "$current" -q >> "$logfile" && git merge "$repo"/"$branch" -q >> "$logfile"
    echo "Release has been merged to $current"
  fi
)
catch || {
  echo "Abort!"
  echo "return with code: $ex_code"
}
