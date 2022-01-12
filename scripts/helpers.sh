#!/bin/bash

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

# set default branch
branch="release"

# set default repo
repo="origin"

# merge log file
merge_log_file="${rootpath}/scripts/.git-merge.log"

# diff log file
diff_log_file="${rootpath}/scripts/.diff.log"

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

# Set git-config values known to fix git errors
git config core.eol lf
git config core.autocrlf false
git config fsck.zeroPaddedFilemode ignore
git config fetch.fsck.zeroPaddedFilemode ignore
git config receive.fsck.zeroPaddedFilemode ignore

if [ "${1}" != "--source-only" ]; then
    main "${@}"
fi
