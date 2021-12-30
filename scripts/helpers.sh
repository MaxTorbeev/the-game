#!/bin/bash

# set default branch
branch="release"

# set default repo
repo="origin"

function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

function throw()
{
    exit $1
}

function catch()
{
    export ex_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $ex_code
}

function throwErrors()
{
    set -e
}

function ignoreErrors()
{
    set +e
}

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

#while getopts ":b:r:" opt; do
#    case $opt in
#      b) branch="$OPTARG" ;;
#      r) repos="$OPTARG" ;;
#      \?) echo "Invalid option -$OPTARG" >&2
#      exit 1 ;;
#    esac
#
#    case $OPTARG in
#      -*) echo "Option $opt needs a valid argument"
#      exit 1 ;;
#    esac
#  done

if [ "${1}" != "--source-only" ]; then
    main "${@}"
fi
