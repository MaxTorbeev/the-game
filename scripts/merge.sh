#!/bin/bash

# set exit on any error
set -e

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

# скрипт проверки возможности слияния.
# Принимает параметр - с какой веткой мерджить, если не задан, то берем ветку release.

#echo $rootpath
#cd "$rootpath" && /bin/bash ./scripts/git-pull.sh
cd "$rootpath" && /bin/bash ./scripts/git-merge.sh

