#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

make_worktree_here() {
    if [[ $# -ne 1  ]]; then
        echo "Usage: make_worktree_here <worktree-name>"
        echo "Creates a new git worktree for the current branch in ../worktrees/<repo-name>/<worktree-name>"
        return 1
    fi

    local repo_dir base_branch_name worktree_name
    worktree_name=$1
    base_branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    repo_dir=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$repo_dir" ]]; then
        echo "Error: Not inside a git repository."
        return 1
    fi

    local worktrees_dir="${repo_dir}/../worktrees/$(basename "$repo_dir")"
    mkdir -p "$worktrees_dir"

    git worktree add "${worktrees_dir}/${worktree_name}"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create worktree for branch '$base_branch_name'."
        return 1
    fi

    echo "Created new worktree at ${worktrees_dir}/${worktree_name} based on branch '$base_branch_name'."
    git worktree list
}

make_autorun_dirs() {
    if [[ $# -ne 0 ]]; then
        echo "Usage: make_autorun_dirs"
        echo "Sync the autorun directories for all git worktrees of the current repository."
        return 1
    fi

    local repo_dir=$(git rev-parse --show-toplevel 2>/dev/null)
    local config_items=(.markdownlint.json .vscode cspell.json)
    local maestro_playbooks_repo="${HOME}/src/Maestro-Playbooks"

    if [[ -z "$repo_dir" ]]; then
        echo "Error: Not inside a git repository."
        return 1
    fi
    for worktree_path in $(git worktree list --porcelain | grep '^worktree ' | awk '{print $2}'); do
        local autorun_dir=${worktree_path/worktrees\//worktrees\/autorun\/}

        if [[ ! -d "$autorun_dir" ]]; then
            mkdir -p "$autorun_dir"
            echo "Created autorun directory: $autorun_dir"
        fi
    done
    for config_item in $config_items; do
        if [[ -e "${maestro_playbooks_repo}/${config_item}" ]]; then
            ln -sf "${maestro_playbooks_repo}/${config_item}" ../worktrees/autorun/
        fi
    done
}
