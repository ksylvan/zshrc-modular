#!/bin/zsh

# Miscellaneous aliases

# Restart MacOS DNS resolver
alias restart_macos_dns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# My PR count so far this month
alias fabric_pr_count='python3 ~/src/backend-tools/count_merged_prs.py --username ksylvan --repo danielmiessler/fabric'

# libreoffice
alias libreoffice='open -a libreoffice'

# Replace ls with eza if available
if whence -p eza &>/dev/null; then
    alias ls=eza
fi

alias emoji_changelog='(echo "Choose an appropriate emoji for each item in the \
CHANGES list below and re-output the entire markdown block below:"; echo ""; cat) | \
fabric -p ai'

function hosts_update() {
    usage_message="Usage: hosts_update <cmd> [<cmd> <cmd> ...]"
    usage_message+="\n  cmd: appstore, brew, fabric, fabric_versions, linux, win, zshrc"
    usage_message+="\n  or use the all pseudo-command (to run all commands)"
    if [[ $# -eq 0 ]]; then
        echo -e $usage_message
        return 1
    fi

    local _zshrc_dir="${HOME}/.zshrc.d"
    if [[ -r "$_zshrc_dir/data/update_hosts.zsh" ]]; then
        source "$_zshrc_dir/data/update_hosts.zsh"
    else
        echo "Error: Could not source update_hosts.zsh data file."
        return 1
    fi
    local win_hosts=("${_ZHU_WIN_HOSTS[@]}")
    local mac_brew_hosts=("${_ZHU_MAC_BREW_HOSTS[@]}")
    local mac_appstore_hosts=("${_ZHU_MAC_APPSTORE_HOSTS[@]}")
    local linux_hosts=("${_ZHU_LINUX_HOSTS[@]}")
    local zshrc_hosts=("${_ZHU_ZSHRC_HOSTS[@]}")
    local fabric_hosts=("${_ZHU_FABRIC_HOSTS[@]}")

    if _running_in_wsl; then
        fabric_hosts+="localhost"
        linux_hosts+="localhost"
        zshrc_hosts+="localhost"
    fi

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
                echo "${COLOR_GREEN}Updating App Store on ${_mas_host}${COLOR_RESET}"
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
                echo "${COLOR_GREEN}Updating brew on $_brew_host${COLOR_RESET}"
                ssh $_brew_host "source .zprofile && brew update && brew upgrade && brew doctor && brew cleanup"
                echo "Done"
                echo ""
            done
            unset _brew_host
            ;;
        fabric)
            local _strategies_git="https://github.com/danielmiessler/fabric.git"

            echo "${COLOR_GREEN}Running git to sync fork of fabric repo:${COLOR_RESET}"
            local _fabric_repo_check="$(fabric_update)"
            local _fabric_error=false
            if [[ "${_fabric_repo_check}" == *ERROR* ]]; then
                _fabric_error=true
            fi
            echo "${_fabric_repo_check}"

            if [[ ${_fabric_error} = 'false' ]]; then
                echo ""
                for _fabric_host in $fabric_hosts; do
                    _fabric_host=$(_validated_hostname $_fabric_host)
                    if [[ -z "$_fabric_host" ]]; then
                        continue
                    fi
                    fabric_deploy -url $_strategies_git $_fabric_host
                done
            fi
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
                echo "${COLOR_GREEN}Updating Linux packages on $_linux_host${COLOR_RESET}"
                ssh $_linux_host "sudo apt-get update && sudo apt-get -y upgrade && sudo snap refresh"
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
                echo "${COLOR_GREEN}Updating Windows packages on $_win_host${COLOR_RESET}"
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
                echo "${COLOR_GREEN}Updating zsh startup files for $_zsh_u_host${COLOR_RESET}"
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
