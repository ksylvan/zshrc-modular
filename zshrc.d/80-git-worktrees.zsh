#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}


function gh_repo_sync() {
    if git_fork_here 2>&1 >/dev/null; then
        echo "Syncing forked repository..."
        local repo=$(git remote -v | grep origin | sed -e "s/.*://" | sed "s/\.git .*//" | uniq)
        gh repo sync "$repo"
    else
        echo "Not a forked repository. Skipping sync."
        return 0
    fi
}

function git_fork_here() {
    if [[ ! -e .git ]]; then
        echo "ERROR: Not a git repository: $PWD"
        return 1
    fi

    local repo
    repo=$(git remote -v | grep origin | sed -e "s/.*://" | sed "s/\.git .*//" | uniq)

    if ! command -v gh &> /dev/null; then
        echo "ERROR: gh CLI is not installed"
        return 1
    fi

    gh repo view "$repo" --json isFork --jq '.isFork' | grep -q true
    if [[ $? -ne 0 ]]; then
        echo false
        return 1
    else
        echo true
        return 0
    fi
}

make_worktree_here() {
    if [[ $# -ne 1  ]]; then
        echo "Usage: make_worktree_here <worktree-name>"
        echo "Creates a new git worktree for the current branch in ../worktrees/<repo-name>/<worktree-name>"
        return 1
    fi

    local magic_configs=(".vercel" ".neon")
    local repo_dir base_branch_name worktree_name
    worktree_name=$1
    base_branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    repo_dir=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$repo_dir" ]]; then
        echo "Error: Not inside a git repository."
        return 1
    fi

    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ "$git_common_dir" != ".git" ]]; then
        repo_dir="${git_common_dir%/.git}"
    fi

    local worktrees_dir="${repo_dir}/../worktrees/$(basename "$repo_dir")"
    mkdir -p "$worktrees_dir"

    git worktree add "${worktrees_dir}/${worktree_name}"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create worktree for branch '$base_branch_name'."
        return 1
    fi

    # symlink all .env* files
    for env_file in $(ls -A "${repo_dir}" | grep '^\.env'); do
        # symlink but avoid overwriting existing files and fail silently
        ln -s "${repo_dir}/${env_file}" "${worktrees_dir}/${worktree_name}/${env_file}" 2>/dev/null || :
    done
    for config in $magic_configs; do
        if [[ -e "${repo_dir}/${config}" ]]; then
            ln -s "${repo_dir}/${config}" "${worktrees_dir}/${worktree_name}/${config}"
        fi
    done

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

cleanup_work_tree_here() {
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: cleanup_work_tree_here <worktree-name> [--force]"
        echo "Removes the specified git worktree and prunes it from the main repository."
        return 1
    fi

    local worktree_name="$1"
    local force_remove="${2:-}"

    local base_branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    local repo_dir=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$repo_dir" ]]; then
        echo "Error: Not inside a git repository."
        return 1
    fi

    local num_of_worktrees=$(git worktree list | wc -l)
    if [[ $num_of_worktrees -le 1 ]]; then
        echo "Error: Cannot remove the last remaining worktree."
        return 1
    fi

    local top_worktree=$(git worktree list --porcelain | grep '^worktree ' | head -n1 | awk '{print $2}')
    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ "$git_common_dir" != ".git" ]]; then
        repo_dir="${git_common_dir%/.git}"
    fi

    local worktrees_dir="${repo_dir}/../worktrees/$(basename "$repo_dir")"
    if [[ ! -d "${worktrees_dir}/${worktree_name}" ]]; then
        echo "Error: Worktree '${worktree_name}' does not exist."
        return 1
    fi

    local worktree_path="${worktrees_dir}/${worktree_name}"
    git worktree remove "${worktree_path}" $force_remove
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to remove worktree '${worktree_name}'."
        return 1
    fi
    git worktree prune
    echo "Removed worktree '${worktree_name}' and pruned from repository."

    cd "$top_worktree"
    echo "Current directory changed to top-level worktree: $top_worktree"
    git worktree list

    local autorun_dir=${worktree_path/worktrees\//worktrees\/autorun\/}
    if [[ -d "$autorun_dir" ]]; then
        echo -n "Should we remove autorun directory: $autorun_dir? (y/n) [n] "
        read -r answer
        if [[ "$answer" != "y" ]]; then
            echo "Skipping removal of autorun directory."
            return 0
        fi
        rm -rf "$autorun_dir"
        echo "Removed autorun directory: $autorun_dir"
    fi
}
