#!/bin/bash

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

. "$rootpath"/scripts/helpers.sh --source-only
# Set exit on any error
set -e

# Clear log files
> "$merge_log_file";
> "$diff_log_file";

# get parameters
while getopts b:r:f flag
do
    case "${flag}" in
        f) force=true;;
        b) branch=${OPTARG};;
        r) repo=${OPTARG};;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Current branch
current=$( git symbolic-ref --quiet --short HEAD || git rev-parse HEAD );
current_remote=$( git rev-parse --abbrev-ref --symbolic-full-name @{u} );

echo "Слияние ветки ${branch}... "

try
(
  if [ -n "$( git -C "${rootpath}" diff -b -w --name-only "${current}" "${current_remote}" | cat )" ]; then
    echo "Ошибка. Ветки ${current} не совпадает с удаленным репозиторием";
    exit 0;
  fi

  if [ -z "$( git ls-remote --exit-code --heads ${repo} ${branch} )" ]; then
    echo "Ошибка. Ветки ${branch} не существует в ${repo}";
    exit 0;
  fi

  # Save branch differences to log file
  git -C "${rootpath}" diff -b -w --name-only "${current}" "${repo}"/"${branch}" > "$diff_log_file"

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
  difference=$( git -C ${rootpath} diff -b -w --stat ${current} ${repo}/${branch} -- . ${ignores} | cat );

  # Check conflicts
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
