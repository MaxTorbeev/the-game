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

echo "Слияние ветки ${branch}... "

try
(
  # Get .gitdiffignore file
  # Wrap all strings in quotes and remove spaces
  ignore_file="$rootpath"/.gitdiffignore;

  if [ -f "${ignore_file}" ]; then
    ignores=$( cat -s "${ignore_file}" | tr '\n' ' ' );
  fi

  # Current branch
  current=$( git symbolic-ref --quiet --short HEAD || git rev-parse HEAD );

  # Check git status
  status="$( git -C "$rootpath" status -uno --porcelain )";

  if [ -n "$status" ]; then
    echo "Error. There are no saved files: ";
    echo "$status";

    exit 0;
  fi

  echo "Текущая ветка $current имеет хэш $( git rev-parse --short HEAD )";

  # Try merge current branch with remote
  git fetch "$repo" "$branch" -q && git merge "$branch" "$repo"/"$branch" -q;

  # Difference current branch with remote release and save to log file
  git -C "${rootpath}" diff -b -w --compact-summary "${current}" "${repo}"/"${branch}" -- . ':!.gitdiffignore' "${ignores}" > "$diff_log_file";

  difference=$( cat -s "$diff_log_file" );
  conflicts=$( git diff --name-only --diff-filter=U );

  # Check for conflicts
  if [ -n "$conflicts" ]; then
    echo "Error. Conflicts: ";
    echo "$conflicts";
    echo "Completed with errors. Branch conflict.";

    exit 1;
  fi

  if [ -n "$difference" ]; then
    echo "Error. There is a difference: ";
    echo "$difference";
    echo "Completed with errors. There are differences in branches.";

    exit 1;
  fi

  echo "=======";
  echo "Merge ${branch} branch to ${current} was successful";

  git -q push;
  echo "Pushed to remote";

  echo "Done!";
  exit 0;
)
catch || {
  echo "Return with code: ${ex_code}. Reset ${current} branch.";
  git reset --hard;

  echo "Abort!"
}
