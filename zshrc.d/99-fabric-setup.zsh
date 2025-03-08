FABRIC_BOOTSTRAP="$HOME/.config/fabric/fabric-bootstrap.inc"

if [[ -f "$FABRIC_BOOTSTRAP" ]]; then
    source "$FABRIC_BOOTSTRAP"
fi

# fabric update and deploy to all my machines
alias fabric_update='gh repo sync ksylvan/fabric; pushd ~/src/fabric;\
  echo "In directory: $(pwd)"; git pull; cd ~/src/custom-fabric;\
  echo "In directory: $(pwd)"; git pull; popd'

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

function __is_windows_host() {
    if [ $# -ne 1 ]; then
        echo "Usage: __is_windows_host hostname"
        return
    fi
    local os=$(remote_host_os $1)
    local ret=false
    echo "$os" | grep -i -q windows
    if [ $? -eq 0 ]; then ret=true; fi
    echo $ret
}

function __fabric_patterns_setup() {
    if [ $# -ne 1 ]; then
        echo "Usage: __fabric_patterns_setup hostname"
        echo "Uses expect script and ssh to run remote commands."
        return 1
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"

    local shell_prompt='\\$ '
    local fabric_cmd='~/go/bin/fabric'
    if [ "$is_win" = "true" ]; then
        shell_prompt='>'
        fabric_cmd='fabric'
    fi

    # Grab the pattern menu number
    patterns_line=$(ssh "$host" "echo '' | ${fabric_cmd} -S" | grep Patterns)
    pattern_number=$(echo "$patterns_line" | sed -n 's/^[[:space:]]*\[\([0-9]\{1,\}\)\].*/\1/p')

    echo "Running fabric -S on $host to update patterns"
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
send "\r"
send "exit\r"
expect eof
EOF
    echo "Completed updating $host fabric patterns"
}

function __run_go_on_host() {
    if [ $# -lt 3 ]; then
        echo "Usage: ____run_go_on_host hostname directory sub-command [args...]"
        return
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"
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

function __fabric_purge_binaries() {
    if [ $# -ne 1 ]; then
        echo "Usage: __fabric_purge_binaries hostname"
        return
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        __run_go_on_host "$host" 'src\\fabric' clean -i -r -cache
    else
        __run_go_on_host "$host" 'src/fabric' clean -i -r -cache
    fi
}

function __fabric_git_pull() {
    if [ $# -ne 1 ]; then
        echo "Usage: __fabric_git_pull hostname"
        return
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        ssh "$host" 'cd src\\fabric && git checkout main && git pull'
    else
        ssh "$host" 'cd src/fabric && git checkout main && git pull'
    fi
}

function __fabric_recompile() {
    if [ $# -ne 1 ]; then
        echo "Usage: __fabric_recompile hostname"
        return
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        __run_go_on_host "$host" 'src\\fabric' install .
    else
        __run_go_on_host "$host" 'src/fabric' install .
    fi
}

function __fabric_version() {
    if [ $# -ne 1 ]; then
        echo "Usage: __fabric_version hostname"
        return
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        ssh -T "$host" '.\go\bin\fabric --version' </dev/null
    else
        ssh -T "$host" './go/bin/fabric --version' i </dev/null
    fi
}

function __fabric_custom() {
    if [ $# -ne 1 ]; then
        echo "Usage: __fabric_custom hostname"
        return
    fi

    local host="$1"
    local is_win="$(__is_windows_host $host)"

    if [ "$is_win" = "true" ]; then
        ssh "$host" 'cd src\custom-fabric && pwsh -nop .\update-fabric.ps1'
    else
        ssh "$host" 'cd src/custom-fabric && ./update-fabric.sh'
    fi
}

function fabric_deploy() {
    for host in "$@"; do
        echo "Installing latest fabric on $host"
        ver_before="$(__fabric_version $host)"
        __fabric_git_pull $host
        __fabric_recompile $host
        ver_after="$(__fabric_version $host)"

        if [ "$ver_before" = "$ver_after" ]; then
            echo "No update needed. Fabric version: $ver_before"
        else
            echo "Updated from ${ver_before} to ${ver_after}"
        fi

        __fabric_patterns_setup $host
        __fabric_custom $host
        echo "Done updating fabric on $host"
        echo ""

    done
}
