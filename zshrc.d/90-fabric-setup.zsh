#!/bin/zsh

FABRIC_BOOTSTRAP="$HOME/.config/fabric/fabric-bootstrap.inc"

if [[ -f "$FABRIC_BOOTSTRAP" ]]; then
    source "$FABRIC_BOOTSTRAP"
fi

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
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: _fabric_setup hostname [strategies_git_url]"
        echo "Uses expect script and ssh to run remote commands."
        return 1
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    strategies_git="https://github.com/danielmiessler/fabric.git"
    if [ $# -eq 2 ]; then
        strategies_git="$2"
    fi

    local shell_prompt='\\$ '
    local fabric_cmd='~/go/bin/fabric'
    if [ "$is_win" = "true" ]; then
        shell_prompt='>'
        fabric_cmd='fabric'
    fi

    # Grab the pattern menu number
    patterns_line=$(ssh "$host" "echo '' | ${fabric_cmd} -S" | grep 'Patterns - Downloads')
    pattern_number=$(echo "$patterns_line" | sed -n 's/^[[:space:]]*\[\([0-9]\{1,\}\)\].*/\1/p')

    # Grab the strategies menu number
    strategies_line=$(ssh "$host" "echo '' | ${fabric_cmd} -S" | grep 'Strategies - Downloads')
    strategies_number=$(echo "$strategies_line" | sed -n 's/^[[:space:]]*\[\([0-9]\{1,\}\)\].*/\1/p')

    echo "Running fabric -S on $host to update patterns and strategies"
    expect <<EOF
log_user 0
set timeout -1
spawn ssh $host
expect "$shell_prompt"
send "fabric -S\r"
expect ":"
send "$pattern_number\r"
expect ":"
send "\r"
expect ":"
send "\r"
expect "(leave empty to skip):"
send "$strategies_number\r"
expect ":"
send "https://github.com/ksylvan/fabric.git\r"
expect ":"
send "\r"
expect "(leave empty to skip):"
send "\r"
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

function _fabric_purge_patterns() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_purge_patterns hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    echo "Purging patterns on $host"
    if [ "$is_win" = "true" ]; then
        ssh "$host" 'cd .config\\fabric && rmdir /s /q patterns'
    else
        ssh "$host" 'cd .config/fabric && rm -rf patterns'
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
        _run_go_on_host "$host" 'src\\fabric' install .
        _run_go_on_host "$host" 'src\\fabric\\plugins\\tools\\to_pdf' install .
        _run_go_on_host "$host" 'src\\fabric\\plugins\\tools\\code_helper' install .
    else
        _run_go_on_host "$host" 'src/fabric' install .
        _run_go_on_host "$host" 'src/fabric/plugins/tools/to_pdf' install .
        _run_go_on_host "$host" 'src/fabric/plugins/tools/code_helper' install .
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

function _fabric_custom() {
    if [ $# -ne 1 ]; then
        echo "Usage: _fabric_custom hostname"
        return
    fi

    local host="$1"
    local is_win="$(_is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        ssh "$host" 'cd src\custom-fabric && git pull && pwsh -nop .\update-fabric.ps1'
    else
        ssh "$host" 'cd src/custom-fabric && git pull && ./update-fabric.sh'
    fi
}

function fabric_deploy() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: fabric_deploy [-url strategies_git_url] hostname"
        return
    fi

    local strategies_git=""
    if [[ "$1" = "-url" ]]; then
        if [[ $# -lt 3 ]]; then
            echo "Usage: fabric_deploy [-url strategies_git_url] hostname"
            return
        fi
        strategies_git="$2"
        shift 2
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
        echo "Updated from ${ver_before} to ${ver_after}"
    fi

    _fabric_purge_patterns $host
    _fabric_setup $host $strategies_git
    _fabric_custom $host
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
