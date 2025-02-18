#!/bin/bash
version=0.0.0A

total=0
oks=0
warnings=0
errors=0

uncommitted=0
unsynced=0

ahead=0
behind=0
diverged=0
noupstream=0

start_time=$(date +%s)
ROOT_DIR=${1:-"/"}

line() {
    width=$(tput cols)
    printf '%*s\n' "$width" | tr ' ' '-'
}

newline() {
    echo ""
}

line
echo "Gitmgr Scanner V. $version"
echo "Scanning $ROOT_DIR..."
newline

while read git_dir; do
    repo_dir=$(dirname "$git_dir")
    cd "$repo_dir" || continue
    ((total++))

    git remote update > /dev/null 2>&1
    LOCAL_AHEAD=$(git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null | awk '{print $1}')

    UPSTREAM="@{upstream}"
    if git rev-parse --verify "$UPSTREAM" >/dev/null 2>&1; then
        read LOCAL_AHEAD LOCAL_BEHIND < <(git rev-list --count --left-right "$UPSTREAM"...HEAD 2>/dev/null)

        if [[ "$LOCAL_AHEAD" -gt 0 && "$LOCAL_BEHIND" -gt 0 ]]; then
            syncstatus="diverged"
            synccolor=33
            syncok=0

            ((unsynced++))
            ((diverged++))
        elif [[ "$LOCAL_AHEAD" -gt 0 ]]; then
            syncstatus="ahead ($LOCAL_AHEAD commits)"
            synccolor=33
            syncok=0

            ((unsynced++))
            ((ahead++))
        elif [[ "$LOCAL_BEHIND" -gt 0 ]]; then
            syncstatus="behind ($LOCAL_BEHIND commits)"
            synccolor=33
            syncok=0

            ((unsynced++))
            ((behind++))
        else
            syncstatus="synced"
            synccolor=32
            syncok=1
        fi
    else
        syncstatus="no upstream"
        synccolor=33
        syncok=0

        ((unsynced++))
        ((noupstream++))
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

        if [[ $syncok -gt 0 ]]; then
            statuscolor=32
            ((oks++))
        else
            statuscolor=33
            ((warnings++))
        fi
    fi

    echo -e "\e[${statuscolor}m[*]\e[0m (\e[${commitcolor}m$commitstatus\e[0m, \e[${synccolor}m$syncstatus\e[0m):\t$repo_dir"
done < <(find "$ROOT_DIR" -type d -name ".git")

end_time=$(date +%s)
elapsed=$((end_time - start_time))

print() {
    name=$1
    count=$2
    color=${3:-0}
    type=${4:-"repositories"}

    echo -e "\e[${color}m$name\e[0m:\t$count $type"
}

echo -e "\nGit findings for $ROOT_DIR:"
print "Total" $total
print "Elapsed" $elapsed 0 "seconds"
newline
print "OK" $oks 32
print "Warnings" $warnings 33
print "Errors" $errors 31
newline
print "Uncommitted" $uncommitted 31
print "Not synced" $unsynced 33
newline
print "Ahead" $ahead 33
print "Behind" $behind 33
print "Diverged" $diverged 33
print "No upstream" $noupstream 33
line
