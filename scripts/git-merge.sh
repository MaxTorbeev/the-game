#!/bin/bash

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

. "$rootpath"/scripts/helpers.sh --source-only

# set exit on any error
set -e

# Clear log files
> "$merge_log_file";
> "$diff_log_file";

try
(
  # Get .gitdiffignore file
  # Wrap all strings in quotes and remove spaces
  ignores=$(cat -s "$rootpath"/.gitdiffignore | tr '\n' ' ' )

  # Current branch
  current=$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)

  echo "======="
  echo "Current branch $current with hash $( git rev-parse --short HEAD )"
  echo "======="

  # Release branch is exists
  if [ -n "$( git show-ref refs/heads/"$branch")" ]; then
    # Remove old local release branch
    git branch -D "$branch" >> "$merge_log_file"
  fi

  # Create actual local release branch and checkout him
  git checkout -b "$branch" "$repo"/"$branch";
  # Checkout to current branch
  git checkout "$current" -q >> "$merge_log_file";
  # and update branch from repo
  git merge "$branch" -q >> "$merge_log_file" ;

  # Difference current branch with remote release and save to log file
  git -C ${rootpath} diff -b -w --compact-summary ${current} ${repo}/${branch} ${ignores} > $diff_log_file;

  difference=$(cat -s "$diff_log_file" )

  if [ -n "$difference" ]; then
    conflicts= $( git diff --name-only --diff-filter=U );

    if [ -n "$conflicts" ]; then
      echo "Conflicts: ";
      echo "$conflicts";
      echo "======="
      git reset --hard >/dev/null 2>&1 ;
      exit 1;
    fi

    echo "There is a difference: ";
    echo "$difference";
    echo "======="
    git checkout "$current" >/dev/null 2>&1 ;

    echo "There are differences in the code" >> "$merge_log_file"
    exit 1;
  else
    git checkout "$current" -q >> "$merge_log_file" ;
    git merge "$branch" -q >> "$merge_log_file" ;
    echo "======="
    echo "Finished!"
    exit 0;
  fi
)
catch || {
  echo "Abort!"
  echo "return with code: $ex_code"
  git branch -D "$branch"
  echo "Remove local $branch"
}
