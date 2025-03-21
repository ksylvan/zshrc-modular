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
    echo "In directory: $(pwd)"
    git stash && git pull && git stash pop

    cd ~/src/custom-fabric
    echo "In directory: $(pwd)"
    git stash && git pull && git stash pop
    cd $_pwd
}

# The following are for multi-os updates of fabric
function remote_host_os() {
    if [ $# -ne 1 ]; then
        echo "Usage: remote_host_os hostname"
        echo "Uses ssh to run remote commands."
        return 1
    fi
    local uname_output="$(ssh "$1" uname -a 2>&1)"
    echo "$uname_output" | grep -q 'is not recognized'
    if [ $? -ne 0 ]; then
        echo "$uname_output"
    else
        local ver_output="$(ssh "$1" ver 2>&1)"
        echo "$ver_output" | grep -q 'is not recognized'
        if [ $? -ne 0 ]; then
            echo "$ver_output" | tail -1
        else
            echo "No uname or ver found!"
        fi
    fi
}

function _is_windows_host() {
    if [ $# -ne 1 ]; then
        echo "Usage: _is_windows_host hostname"
        return
    fi
    local os=$(remote_host_os $1)
    local ret=false
    echo "$os" | grep -i -q windows
    if [ $? -eq 0 ]; then ret=true; fi
    echo $ret
}

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
    patterns_line=$(ssh "$host" "echo '' | ${fabric_cmd} -S" | grep Patterns)
    pattern_number=$(echo "$patterns_line" | sed -n 's/^[[:space:]]*\[\([0-9]\{1,\}\)\].*/\1/p')

    # Grab the strategies menu number
    strategies_line=$(ssh "$host" "echo '' | ${fabric_cmd} -S" | grep Strategies)
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
        echo "Usage: __run_go_on_host hostname directory sub-command [args...]"
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
    else
        _run_go_on_host "$host" 'src/fabric' install .
        _run_go_on_host "$host" 'src/fabric/plugins/tools/to_pdf' install .
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
    echo "Installing latest fabric on $host"
    local ver_before="$(_fabric_version $host)"
    _fabric_git_pull $host
    _fabric_recompile $host
    local ver_after="$(_fabric_version $host)"

    if [ "$ver_before" = "$ver_after" ]; then
        echo "No update needed. Fabric version: $ver_before"
    else
        echo "Updated from ${ver_before} to ${ver_after}"
    fi

    _fabric_purge_patterns $host
    _fabric_setup $host $strategies_git
    _fabric_custom $host
    echo "Done updating fabric on $host"
    echo ""
}
