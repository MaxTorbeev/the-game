#!/bin/bash

# set exit on any error
set -e

# path to root repository folder
rootpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; cd "../" >/dev/null 2>&1 ; pwd -P )"

# list of changes
diff="${rootpath}/scripts/.diff.log"

# clearing diff file
> "$diff"

# log file
logfile="${rootpath}/scripts/.git-pull.log"

# clear log file
> "$logfile"

# check git status
status="$(git -C "$rootpath" status -uno --porcelain)"
# if changed
if [ -n "$status" ]; then

    # get parameters
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--force) force=true ;;
            -c|--clean) clean=true ;;
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    echo "There are changes in local code."
    # if force flag is set, reset all changes
    if [ "$force" ]; then
        # stashing changes
        printf "Stashing... "
        git -C "$rootpath" stash >> "$logfile"
        echo "============" >> "$logfile"
        echo "Done!"
        # cleaning untracked files
        if [ "$clean" ]; then
            printf "Clean untracked... "
            git -C "$rootpath" clean -fd
            echo "============" >> "$logfile"
            echo "Done!"
        fi
    # else abort the operation
    else
        echo "Abort!"
        echo "$status"
        exit 1
    fi
fi

# current commit hash
commit=$(git -C "$rootpath" log --pretty=format:'%h' -n 1)

# current branch name
branch=$(git -C "$rootpath" rev-parse --abbrev-ref HEAD)

# pulling changes
printf "Pulling... "
git -C "$rootpath" pull -q --ff-only origin "$branch" >> "$logfile"
echo "Done!"

# new commit hash
new_commit=$(git -C "$rootpath" log --pretty=format:'%h' -n 1)

# if no changes
if [ "$commit" == "$new_commit" ]; then
    echo "No changes "${branch} - "${new_commit}" > "$diff"
# if changes, writing list of all changed files
else
    echo "List of changes "${branch} - "${new_commit}:" > "$diff"
    git -C "$rootpath" diff --name-only "$commit".."$new_commit" >> "$diff"
fi
