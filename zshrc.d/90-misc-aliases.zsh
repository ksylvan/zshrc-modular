#!/bin/zsh

# Miscellaneous aliases

# Restart tailscale after a brew update
alias tailscale_restart='sudo launchctl kickstart -k system/com.tailscale.tailscaled'

# My PR count so far this month
alias fabric_pr_count='python3 ~/src/backend-tools/count_merged_prs.py --username ksylvan --repo danielmiessler/fabric'

# libreoffice
alias libreoffice='open -a libreoffice'

function hosts_update() {
    usage_message="Usage: hosts_update <cmd> [<cmd> <cmd> ...]"
    usage_message+="\n  cmd: appstore, brew, fabric, fabric_versions, linux, win, zshrc"
    usage_message+="\n  or use the all pseudo-command (to run all commands)"
    if [[ $# -eq 0 ]]; then
        echo -e $usage_message
        return 1
    fi

    local win_hosts=(shakti.local) # Add more Windows hosts here
    local mac_brew_hosts=(dharma.local shiva.local zen.local)
    local mac_appstore_hosts=(dharma.local shiva.local)
    local linux_hosts=(thor.local)
    local zshrc_hosts=(dharma.local thor.local shiva.local zen.local)
    local fabric_hosts=(dharma.local thor.local shakti.local shiva.local zen.local)

    local _commands=($@)
    if [[ " ${_commands} " =~ " all " ]]; then
        # Replace 'all' with all available commands
        _commands=()
        for arg in "$@"; do
            if [[ "$arg" == "all" ]]; then
                _commands+=("fabric" "win" "brew" "appstore" "linux" "zshrc")
            else
                _commands+=("$arg")
            fi
        done
        set -- "${_commands[@]}"
    fi

    # Ensure commands are unique
    _commands=($(for cmd in "${_commands[@]}"; do echo "$cmd"; done | sort -u))

    for cmd in ${_commands}; do
        case "$cmd" in
        appstore)
            for _mas_host in $mac_appstore_hosts; do
                _mas_host=$(_validated_hostname $_mas_host)
                if [[ -z "$_mas_host" ]]; then
                    continue
                fi
                echo "Updating App Store on ${_mas_host}"
                ssh ${_mas_host} "source .zprofile && mas upgrade"
                echo "Done"
                echo ""
            done
            unset _mas_host
            ;;
        brew)
            for _brew_host in $mac_brew_hosts; do
                _brew_host=$(_validated_hostname $_brew_host)
                if [[ -z "$_brew_host" ]]; then
                    continue
                fi
                echo "Updating brew on $_brew_host"
                ssh $_brew_host "source .zprofile && brew cleanup && brew update && brew upgrade"
                echo "Done"
                echo ""
            done
            unset _brew_host
            ;;
        fabric)
            local _strategies_git="https://github.com/danielmiessler/fabric.git"
            echo "Github sync our fork of fabric first"
            fabric_update
            echo ""
            for _fabric_host in $fabric_hosts; do
                _fabric_host=$(_validated_hostname $_fabric_host)
                if [[ -z "$_fabric_host" ]]; then
                    continue
                fi
                fabric_deploy -url $_strategies_git $_fabric_host
            done
            unset _fabric_host
            ;;
        fabric_versions)
            for _fabric_host in $fabric_hosts; do
                _fabric_host=$(_validated_hostname $_fabric_host)
                if [[ -z "$_fabric_host" ]]; then
                    continue
                fi
                fabric_deploy_info $_fabric_host
            done
            unset _fabric_host
            ;;
        linux)
            for _linux_host in $linux_hosts; do
                _linux_host=$(_validated_hostname $_linux_host)
                if [[ -z "$_linux_host" ]]; then
                    continue
                fi
                echo "Updating Linux packages on $_linux_host"
                ssh $_linux_host "sudo apt update && sudo apt -y upgrade && sudo snap refresh"
                echo "Done"
                echo ""
            done
            unset _linux_host
            ;;
        win)
            for _win_host in $win_hosts; do
                _win_host=$(_validated_hostname $_win_host)
                if [[ -z "$_win_host" ]]; then
                    continue
                fi
                echo "Updating Windows packages on $_win_host"
                ssh $_win_host "scoop update && scoop status && scoop update *"
                ssh $_win_host "winget upgrade"
                echo "Done"
                echo ""
            done
            unset _win_host
            ;;
        zshrc)
            for _zsh_u_host in $zshrc_hosts; do
                _zsh_u_host=$(_validated_hostname $_zsh_u_host)
                if [[ -z "$_zsh_u_host" ]]; then
                    continue
                fi
                echo "Updating zsh startup files for $_zsh_u_host"
                ssh $_zsh_u_host "cd src/zshrc-modular && git pull && ./install"
                echo "Done"
                echo ""
            done
            ;;
        *)
            echo "Unknown command: $cmd"
            echo -e $usage_message
            return 1
            ;;
        esac
    done
}
