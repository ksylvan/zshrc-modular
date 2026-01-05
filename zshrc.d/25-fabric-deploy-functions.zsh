#!/bin/zsh

# fabric update and deploy to all my machines
function fabric_update() {
    gh repo sync ksylvan/fabric
    local _pwd=$(pwd)
    cd ~/src/fabric
    # Check if the current directory is a git repository and if it's dirty
    local _git_cmd_output=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        _git_cmd_output="$(git status --porcelain)"
        if [[ -n "${_git_cmd_output}" ]]; then
            _git_cmd_output="ERROR: Local fabric repository is dirty\n${_git_cmd_output}"
        else
            # Fabric repository is clean.
            _git_cmd_output="$(git pull)"
        fi
    else
        _git_cmd_output="ERROR: $(pwd) is not a git repository"
    fi
    cd $_pwd
    echo "${_git_cmd_output}"
}

# The following are for multi-os updates of fabric
function _fabric_setup() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: _fabric_setup hostname"
        return 1
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    local shell_prompt='\\$ '
    local fabric_cmd='~/go/bin/fabric'
    if [ "$is_win" = "true" ]; then
        shell_prompt='>'
        fabric_cmd='fabric'
    fi

    # After purging patterns, first-time setup is triggered
    echo "Running fabric -S on $host (first-time setup flow after pattern purge)"
    expect <<EOF
log_user 0
set timeout -1
spawn ssh $host
expect "$shell_prompt"
send "fabric -S\r"
# Patterns: Git Repo Url prompt (accept default)
expect ":"
send "\r"
# Patterns: Git Repo Patterns Folder prompt (accept default)
expect ":"
send "\r"
# Strategies: Git Repo Url prompt
expect ":"
send "\r"
# Strategies: Git Repo Strategies Folder prompt (accept default)
expect ":"
send "\r"
# Done - wait for shell prompt
expect "$shell_prompt"
send "exit\r"
expect eof
EOF
    echo "Completed updating $host fabric patterns and strategies"
}

function _run_go_on_host() {
    if [ $# -lt 3 ]; then
        echo "Usage: _run_go_on_host hostname directory sub-command [args...]"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"
    local remote_dir="$2"
    shift 2

    echo Running ssh "$host" "cd \"${remote_dir}\" && go ${@}"
    if [ "$is_win" = "true" ]; then
        ssh "$host" "cd \"${remote_dir}\" && go ${@}"
    else
        local remote_shell="$(ssh $host 'echo $SHELL')"
        if [ "$remote_shell" = "/bin/zsh" ]; then
            ssh "$host" "cd \"${remote_dir}\" && PATH=/usr/local/bin:\$PATH:/opt/homebrew/bin && go ${@}"
        else
            ssh "$host" "cd \"${remote_dir}\" && go ${@}"
        fi
    fi
}

function _fabric_purge_patterns_and_strategies() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_purge_patterns_and_strategies hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    echo "Purging patterns and strategies on $host"
    if [ "$is_win" = "true" ]; then
        ssh "$host" 'cd .config\\fabric && rmdir /s /q patterns strategies'
    else
        ssh "$host" 'cd .config/fabric && rm -rf patterns strategies'
    fi
}

function _fabric_purge_binaries() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_purge_binaries hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        _run_go_on_host "$host" 'src\\fabric' clean -i -r -cache
    else
        _run_go_on_host "$host" 'src/fabric' clean -i -r -cache
    fi
}

function _fabric_git_pull() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_git_pull hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        ssh "$host" 'cd src\\fabric && git checkout main && git pull'
    else
        ssh "$host" 'cd src/fabric && git checkout main && git pull'
    fi
}

function _fabric_recompile() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_recompile hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        _run_go_on_host "$host" 'src\\fabric\\cmd\\fabric' install .
    else
        _run_go_on_host "$host" 'src/fabric/cmd/fabric' install .
    fi
}

function _fabric_helpers_recompile() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_recompile hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        _run_go_on_host "$host" 'src\\fabric\\cmd\\to_pdf' install .
        _run_go_on_host "$host" 'src\\fabric\\cmd\\code2context' install .
        _run_go_on_host "$host" 'src\\fabric\\cmd\\generate_changelog' install .
    else
        _run_go_on_host "$host" 'src/fabric/cmd/to_pdf' install .
        _run_go_on_host "$host" 'src/fabric/cmd/code2context' install .
        _run_go_on_host "$host" 'src/fabric/cmd/generate_changelog' install .
    fi
}


function _fabric_version() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_version hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        ssh -T "$host" '.\go\bin\fabric --version' </dev/null
    else
        ssh -T "$host" './go/bin/fabric --version' i </dev/null
    fi
}

function _fabric_completions() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_completions hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        echo "Ignoring completions on Windows host $host"
        return
    fi
    echo "Installing fabric completions on $host"
    ssh "$host" 'cd src/fabric; mkdir -p ~/.zsh/completions/ && cp completions/_fabric ~/.zsh/completions/'
    ssh "$host" 'cd ~/.zsh/completions/ && ln -sf _fabric _fabric-ai'
    echo "Done installing on $host: _fabric and _fabric-ai in ~/.zsh/completions/"
}


function _fabric_custom() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_custom hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        echo "Running custom fabric update script on Windows host $host"
        ssh "$host" 'cd src\custom-fabric && git pull && pwsh -nop .\update-fabric.ps1'
    else
        echo "Running custom fabric update script on host $host"
        ssh "$host" 'cd src/custom-fabric && git pull && ./update-fabric.sh'
    fi
}

function fabric_deploy() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: fabric_deploy hostname"
        return
    fi

    local host="$1"
    echo "${COLOR_GREEN}Installing latest fabric on $host${COLOR_RESET}"
    local ver_before="$(_fabric_version $host)"
    _fabric_git_pull $host
    _fabric_recompile $host
    local ver_after="$(_fabric_version $host)"

    if [[ "$ver_before" = "$ver_after" ]]; then
        echo "No update needed. Fabric version: $ver_before"
        if [[ -z "${FABRIC_SETUP_PATTERNS_EVEN_IF_SAME}" ]]; then
            echo "Skipping fabric setup on $host"
            echo ""
            return
        fi
    else
        _fabric_helpers_recompile $host
        echo "Updated from ${ver_before} to ${ver_after}"
    fi

    _fabric_purge_patterns_and_strategies $host
    _fabric_setup $host
    _fabric_custom $host
    _fabric_completions $host

    echo "Done updating fabric on $host"
    echo ""
}

function fabric_deploy_info() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: fabric_deploy_info hostname"
        return
    fi

    local host="$1"
    echo "Fabric deploy info for $host"
    echo "--------------------------------"
    echo "Fabric version: $(_fabric_version $host)"
    echo "$(os_version $host)"
    echo ""
}

function fabric_packager() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: fabric_packager {winget|docker}"
        return 1
    fi

    local target="$1"
    local event_type=""
    case "$target" in
        winget) event_type="fabric-winget-release" ;;
        docker) event_type="fabric-docker-release" ;;
        *) echo "Usage: fabric_packager {winget|docker}"; return 1 ;;
    esac

    local fabric_version=$(gh api graphql -f query='
    query {
        repository(owner: "danielmiessler", name: "fabric") {
            latestRelease {
                tagName
            }
        }
    }' --jq '.data.repository.latestRelease.tagName')

    local releases_url="$(gh api repos/danielmiessler/fabric/releases/latest --jq '.html_url')"
    echo "Dispatching fabric ${target} release update to ${fabric_version} using assets at ${releases_url}"
    printf '%s' \
        '{"event_type":"'"$event_type"'","client_payload":{"tag":"'"$fabric_version"'","url":"'"$releases_url"'"}}' \
    | gh api repos/ksylvan/fabric-packager/dispatches --method POST --input -
}
