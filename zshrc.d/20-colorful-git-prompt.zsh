#!/bin/zsh

# Set up a colorful prompt with Git branch info

# print the current branch name
parse_git_branch() {
    # Check if we're in a git repository first
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    local branch git_status
    if branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        git_status=$(git status --porcelain 2>/dev/null)
        if [[ -n $git_status ]]; then
            # Count staged and unstaged changes
            local staged=$(echo "$git_status" | grep -c "^[MADRC]")
            local unstaged=$(echo "$git_status" | grep -c "^.[MADRC]")
            local untracked=$(echo "$git_status" | grep -c "^??")

            local status_indicators=""
            [[ $staged -gt 0 ]] && status_indicators+="+"
            [[ $unstaged -gt 0 ]] && status_indicators+="!"
            [[ $untracked -gt 0 ]] && status_indicators+="?"

            echo "[${branch}${status_indicators}] "
        else
            echo "[${branch}] "
        fi
    elif branch=$(git rev-parse --short HEAD 2>/dev/null); then
        echo "[detached@${branch}] "
    fi
}

# Define color escape sequences for prompt sections.
autoload -U colors && colors
COLOR_DEF="%{$reset_color%}"
COLOR_USR="%{$fg[grey]%}" # Grey color for user@host
COLOR_DIR="%{$fg[red]%}"  # Red for current directory
COLOR_GIT="%{$fg[blue]%}" # Blue for git branch

# Enable substitution in the prompt.
setopt PROMPT_SUBST

# Build the prompt:
# - %n: username
# - %m: hostname
# - %2~: current directory, shortened to show two trailing components
# - $(parse_git_branch): insert the current Git branch (if any)
export PROMPT='${COLOR_USR}%n@%m ${COLOR_DIR}%2~ ${COLOR_GIT}$(parse_git_branch)${COLOR_DEF}$ '
