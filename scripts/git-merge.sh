#!/bin/bash

# set exit on any error
set -e

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

# log file
logfile="${rootpath}/scripts/.git-merge.log"

#- взять ветку из параметра (или release), проверить что она актуальна (запулить ремоут и сравнить)
#- смерджить ветки (либо через чекаут на отдельную ветку, либо прям тут)
#- в случае конфликта откатить до первоначального состояния
#- если конфликтов нет, сравнить результат мерджа с веткой, с которой сливали
#- если совпадают, то все ок
#- если отличаются, то возвратить до первоначального состояния
#- локальную ветку, которая была создана для слияния, и локальную копию ветки, которую мы мерджим, нужно удалить
#- в случае какой либо ошибки промежуточной, также откатывать до первоначального состояния
#многие дейсвия уже реализованы в скриптах git-pull.sh и build.sh, можно взять оттуда
#для теста можно использовать репозиторий ibg, у них стоит 48 релиз, задач было залито много последующих релизов, можно попытаться слить с 60 релизом (должны быть различия) и с 63 релизом (различий быть не должно)

currentBranch=$( git symbolic-ref --short HEAD )
currentHead=$( git rev-parse --short HEAD )

echo "Current branch $currentBranch with hash $currentHead"
echo "======="

git checkout release -q >> $logfile && git pull origin release -q >> $logfile

difference="$(git merge-tree "$(git merge-base $currentBranch release)" release $currentBranch | sed -ne '/^\+<<</,/^\+>>>/ p')"

echo $difference

if [ -n "$difference" ]; then
  echo "$difference";
  echo "======="
  git reset --hard
else
  git checkout "$currentBranch" -q >> $logfile && git merge origin/release -q >> $logfile
  echo "Release has been merged to $currentBranch"
fi

