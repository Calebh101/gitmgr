#!/bin/bash

total=0
oks=0
warnings=0
errors=0

uncommitted=0
unsynced=0

ROOT_DIR=$1
echo "Scanning $ROOT_DIR..."

while read git_dir; do
    repo_dir=$(dirname "$git_dir")
    cd "$repo_dir" || continue
    ((total++))

    git remote update > /dev/null 2>&1
    LOCAL_AHEAD=$(git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null | awk '{print $1}')
    
    if [[ -n "$LOCAL_AHEAD" && "$LOCAL_AHEAD" -gt 0 ]]; then
        syncstatus="not synced"
        synccolor=31
        ((unsynced++))
    else
        syncstatus=synced
        synccolor=32
    fi

    if [[ -n $(git status --porcelain) ]]; then
        commitstatus=uncommitted
        commitcolor=31
        statuscolor=31

        ((errors++))
        ((uncommitted++))
    else
        commitstatus=committed
        commitcolor=32

        if [[ $syncstatus == "not synced" ]]; then
            statuscolor=33
            ((warnings++))
        else
            statuscolor=32
            ((oks++))
        fi
    fi

    echo -e "\e[${statuscolor}m[*]\e[0m (\e[${commitcolor}m$commitstatus\e[0m, \e[${synccolor}m$syncstatus\e[0m): $repo_dir"
done < <(find "$ROOT_DIR" -type d -name ".git")

echo -e "\nGit findings for $ROOT_DIR:\n\n\e[32mOK\e[0m: $oks\n\e[33mWarnings\e[0m: $warnings\n\e[31mErrors\e[0m: $errors\nTotal: $total\n\n\e[31mUncommitted\e[0m: $uncommitted\n\e[33mNot synced\e[0m: $unsynced"