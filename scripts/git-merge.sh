#!/bin/bash

. ./helpers.sh --source-only

# set exit on any error
set -e

# log file
logfile="${rootpath}/scripts/.git-merge.log"

try
(
  # Remove old local release branch
  git branch -D "$branch"

  # Create actual local release branch
  git checkout -b "$branch" "$repo" "$branch"

  # Set git-config values known to fix git errors
  git config core.eol lf
  git config core.autocrlf false
  git config fsck.zeroPaddedFilemode ignore
  git config fetch.fsck.zeroPaddedFilemode ignore
  git config receive.fsck.zeroPaddedFilemode ignore

  # current branch
  current=$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)

  echo "Current branch $current with hash $( git rev-parse --short HEAD )"
  echo "======="

  # Checkout to release branch
  # shellcheck disable=SC2129
  git checkout "$branch" -q >> $logfile

  # and update branch from repo
  git pull "$repo" "$branch" -q >> $logfile

  difference=$( git -C "$rootpath" diff -b -w --diff-algorithm=patience --compact-summary "$repo"/"$branch" | cat )
#  isConflict=$( git diff --name-only --diff-filter=U )

  echo $difference;

  git checkout "$current" >/dev/null 2>&1 ;

#  if [ -n "$difference" ]; then
#    echo "There is a difference: ";
#    echo "$difference";
#    echo "======="
#    git checkout "$current" >/dev/null 2>&1 ;
#    git reset --hard >/dev/null 2>&1 ;
#    exit 1;
#  fi
#
#  if [ -n "$isConflict" ]; then
#    echo "Conflict: ";
#    echo "$isConflict";
#    echo "======="
#    git checkout "$current" >/dev/null 2>&1 ;
#  else
#    git checkout "$current" -q >> "$logfile" && git merge "$repo"/"$branch" -q >> "$logfile"
#    echo "Release has been merged to $current"
#  fi
)
catch || {
  echo "Abort!"
  echo "return with code: $ex_code"
}
