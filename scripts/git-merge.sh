#!/bin/bash

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

. "$rootpath"/scripts/helpers.sh --source-only
# set exit on any error
set -e

# Clear log files
> "$merge_log_file";
> "$diff_log_file";

# get parameters
while getopts b:r flag
do
    case "${flag}" in
        b) branch=${OPTARG};;
        r) repo=${OPTARG};;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Merging with ${branch} branch... "

try
(
  # Get .gitdiffignore file
  # Wrap all strings in quotes and remove spaces
  ignores=$(cat -s "$rootpath"/.gitdiffignore | tr '\n' ' ' )

  # Current branch
  current=$(git symbolic-ref --quiet --short HEAD || git rev-parse HEAD)

  # Check git status
  status="$(git -C "$rootpath" status -uno --porcelain)"

  if [ -n "$status" ]; then
    echo "Error. There are no saved files: " >> "$merge_log_file";
    echo "$status" >> "$merge_log_file";
    echo $status;

    exit 0;
  fi

  {
    echo "======="
    echo "Current branch $current with hash $( git rev-parse --short HEAD )"
    echo "======="
  } >> "$merge_log_file"

  # Release branch is exists
  if [ -n "$( git show-ref refs/heads/"$branch")" ]; then
    # Remove old local release branch
    git branch -D "$branch" >> "$merge_log_file"
  fi

  # Create actual local release branch and checkout him
  # Checkout to current branch and update branch from repo
  {
    git checkout -q -b "$branch" "$repo"/"$branch" && git checkout "$current" -q && git merge "$branch" -q
  } >> "$merge_log_file"

  # Difference current branch with remote release and save to log file
  git -C ${rootpath} diff -b -w --compact-summary ${current} ${repo}/${branch} -- . ${ignores} > $diff_log_file;

  difference=$(cat -s "$diff_log_file" )
  conflicts=$( git diff --name-only --diff-filter=U );

  # Check for conflicts
  if [ -n "$conflicts" ]; then
    echo "Error. Conflicts: " >> "$merge_log_file";
    echo "$conflicts" >> "$merge_log_file";
    echo "Completed with errors. Branch conflict.";

    exit 1;
  fi

  if [ -n "$difference" ]; then
    echo "Error. There is a difference: " >> "$merge_log_file";
    echo "$difference" >> "$merge_log_file";
    echo "Completed with errors. There are differences in branches.";

    exit 1;
  fi
  {
    echo "======="
    echo "Merge ${branch} branch to ${current} was successful"
  } >> "$merge_log_file"

  echo "Done!"
  exit 0;
)
catch || {
  {
    echo "Return with code: ${ex_code}. Reset ${current} branch."
    git reset --hard;
    git branch -D "$branch"
  } >> "$merge_log_file"

  echo "Abort!"
}
