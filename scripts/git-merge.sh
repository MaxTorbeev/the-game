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
    echo "Ошибка. Имеются не зафиксированные файлы: ";
    echo "$status";

    exit 0;
  fi

  echo "Текущая ветка $current с последней фиксацией $( git rev-parse --short HEAD )";

  # Try merge current branch with remote
  git fetch "$repo" "$branch" -q && git merge "$repo"/"$branch" -q;

  # Difference current branch with remote release and save to log file
  git -C "${rootpath}" diff -b -w --compact-summary "${current}" "${repo}"/"${branch}" -- . ':!.gitdiffignore' "${ignores}" > "$diff_log_file";

  difference=$( cat -s "$diff_log_file" );
  conflicts=$( git diff --name-only --diff-filter=U );

  # Check for conflicts
  if [ -n "$conflicts" ]; then
    echo "Ошибка. Имеются конфликты: ";
    echo "$conflicts";

    exit 1;
  fi

  if [ -n "$difference" ]; then
    echo "Ошибка. После слияния имеется разница с удаленным репозиторием: ";
    echo "$difference";

    exit 1;
  fi

  echo "=======";
  echo "Слияние ветки ${branch} с ${current} прошло успешно";

  git push;

  echo "Done!";
  exit 0;
)
catch || {
  echo "Возврат в исходное состояние ветки ${current}";
  git reset --hard;
}
