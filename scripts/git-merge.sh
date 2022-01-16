#!/bin/bash

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

. "$rootpath"/scripts/helpers.sh --source-only
# Set exit on any error
set -e

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

try
(
  # Clear log files
  if [ -w "$diff_log_file" ]; then
    > "$diff_log_file";
  else
    echo "Ошибка. Нет прав доступа к файлу ${diff_log_file}"
    exit 0;
  fi

  if [ -w "$merge_log_file" ]; then
    > "$merge_log_file";
  else
    echo "Ошибка. Нет прав доступа к файлу ${merge_log_file}"
    exit 0;
  fi

  # Check git status
  status="$( git -C "$rootpath" status -uno --porcelain )";

  if [ -n "$status" ]; then
    echo "Ошибка. Имеются не зафиксированные файлы: ";
    echo "$status";

    exit 0;
  fi

  if [ -z "$( git ls-remote --exit-code --heads ${repo} ${branch} )" ]; then
    echo "Ошибка. Ветки ${branch} не существует в ${repo}";
    exit 0;
  fi

  if [ -z "${current_remote}" ]; then
      echo "Ошибка. Ветка ${current} не имеет связи с удаленным репозиторием"
      exit 0;
  fi

  if [ "$( git rev-parse "$current_remote" )" != "$( git rev-parse HEAD )" ]; then
    echo "Ошибка. Ветки ${current} не совпадает с удаленной веткой ${current_remote}";
    exit 0;
  fi

  # Try merge current branch with remote
  git fetch "$repo" "$branch" -q || exit 1

  # Save branch differences to log file
  git -C "${rootpath}" diff -b -w --name-only "${current}" "${repo}"/"${branch}" > "$diff_log_file"

  echo "Текущая ветка $current с последней фиксацией $( git rev-parse --short HEAD ) ($( git show-branch --no-name HEAD ))";

  echo "Слияние ветки ${branch}... "

  if [ "$force" ]; then
    git merge -X theirs  "$repo"/"$branch" -q >> "$merge_log_file" || exit 1;
  else
    git merge "$repo"/"$branch" -q  >> "$merge_log_file" || exit 1;

    # Difference current branch with remote release and save to log file
    difference=$( git -C ${rootpath} diff -b -w --stat ${current} ${repo}/${branch} -- . ${ignores} | cat );

    if [ -n "$difference" ]; then
      echo "Ошибка. После слияния имеется разница с удаленным репозиторием: ";
      echo "$difference";

      exit 1;
    fi
  fi

  echo "Слияние ветки ${branch} с ${current} прошло успешно";

  echo "Пуш ветки ${current}...";

  git push -q >> "$merge_log_file" || exit 1;

  echo "Завершено успешно";

  exit 0;
)
catch || {
  echo "Завершено с ошибкой"

  # Check conflicts
  conflicts=$( git diff --name-only --diff-filter=U );

  # Check for conflicts
  if [ -n "$conflicts" ]; then
    echo "Имеются конфликты: ";
    echo "$conflicts";
  fi

  echo "Возврат в исходное состояние ветки ${current}...";
  git reset --hard >/dev/null 2>&1;
  echo "Текущая ветка $current с последней фиксацией $( git rev-parse --short HEAD ) ($( git show-branch --no-name HEAD ))";
}
