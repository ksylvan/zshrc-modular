#!/bin/zsh

function _running_in_wsl() {
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
        return 0
    else
        return 1
    fi
}

function _validated_hostname() {
    local host="$1"
    if [[ -z "$host" ]]; then
        echo "Hostname is required. Returns a validated hostname." >&2
        echo ""
        return 1
    fi
    local hostname_lower=$(hostname | tr '[:upper:]' '[:lower:]')
    if _running_in_wsl && [[ "${host:l}" =~ ${hostname_lower} || ${host:l} =~ ${hostname_lower}.local ]]; then
        echo "Warning: hostname $host is not reachable from WSL. Using the host IP address." >&2
        host=$(powershell.exe -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 |\
                Where-Object { \$_.InterfaceAlias -match 'Wi-Fi|Ethernet' -and \$_.IPAddress -match '^192\.168\.' } \
                | Sort-Object InterfaceMetric | Select-Object -First 1 -ExpandProperty IPAddress" | tr -d '\r')
        echo "$host"
        return 0
    fi

    # Check if the host is reachable
    if nslookup "$host" &>/dev/null; then
        echo "$host"
        return 0
    fi
    # Check if the host is a local hostname and strip the .local suffix
    if [[ "$host" =~ ^[a-zA-Z0-9._-]+\.local$ ]]; then
        host="${host%%.*}"
        if nslookup "$host" &>/dev/null; then
            echo "$host"
            return 0
        fi
    fi
    echo ""
    echo "Error: Could not validate hostname '$host'" >&2
    return 1
}

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

function _is_linux_host() {
    if [ $# -ne 1 ]; then
        echo "Usage: _is_linux_host hostname"
        return
    fi
    local os=$(remote_host_os $1)
    local ret=false
    echo "$os" | grep -i -q linux
    if [ $? -eq 0 ]; then ret=true; fi
    echo $ret
}

function _is_mac_host() {
    if [ $# -ne 1 ]; then
        echo "Usage: _is_mac_host hostname"
        return
    fi
    local os=$(remote_host_os $1)
    local ret=false
    echo "$os" | grep -i -q darwin
    if [ $? -eq 0 ]; then ret=true; fi
    echo $ret
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

function _mac_os_version() {
    if [ $# -ne 1 ]; then
        echo "Usage: _mac_os_version hostname"
        return
    fi
    if [[ $(_is_mac_host $1) = "true" ]]; then
        local os=$(ssh ${1} "sw_vers" 2>&1)
        if [[ -n "$os" ]]; then
            echo "$os"
        else
            echo "Unable to determine macOS version."
        fi
    else
        echo "Not a macOS host."
    fi
}

function _linux_os_version() {
    if [ $# -ne 1 ]; then
        echo "Usage: _linux_os_version hostname"
        return
    fi
    if [[ $(_is_linux_host $1) = "true" ]]; then
        local os=$(ssh ${1} "lsb_release -a" 2>&1)
        if [[ -n "$os" ]]; then
            echo "$os"
        else
            echo "Unable to determine Linux version."
        fi
    else
        echo "Not a Linux host."
    fi
}

function _windows_os_version() {
    if [ $# -ne 1 ]; then
        echo "Usage: _windows_os_version hostname"
        return
    fi
    if [[ $(_is_windows_host $1) = "true" ]]; then
        local ps_cmd='Get-ComputerInfo | ForEach-Object { "$($_.OSName),$($_.OSDisplayVersion),$($_.WindowsBuildLabEx)" }'
        local os=$(ssh ${1} "powershell -NoProfile -Command \"${ps_cmd}\"" 2>&1 | tr -d '\r' | tr '\n' '|')
        os=${os%|} # Remove trailing '|'
        IFS='|' read -r -A os_parts <<<"$os"
        if [[ -n "$os_parts" ]]; then
            echo "OSName:            ${os_parts[1]}"
            echo "OSDisplayVersion:  ${os_parts[2]}"
            echo "WindowsBuildLabEx: ${os_parts[3]}"
        else
            echo "Unable to determine Windows version."
        fi
    else
        echo "Not a Windows host."
    fi
}

function os_version() {
    if [ $# -ne 1 ]; then
        echo "Usage: os_version hostname"
        return
    fi
    local host=$(_validated_hostname $1)
    if [[ -z "$host" ]]; then
        return 1
    fi

    local os=$(remote_host_os $host)
    if [[ $os =~ "Linux" ]]; then
        _linux_os_version $host
    elif [[ $os =~ "Darwin" ]]; then
        _mac_os_version $host
    elif [[ $os =~ "Windows" ]]; then
        _windows_os_version $host
    else
        echo "Unknown OS type."
    fi
}
