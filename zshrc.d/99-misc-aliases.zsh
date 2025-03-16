#!/bin/zsh

# Miscellaneous aliases

# Restart tailscale after a brew update
alias tailscale_restart='sudo launchctl kickstart -k system/com.tailscale.tailscaled'

# My PR count so far this month
alias fabric_pr_count='python3 ~/src/backend-tools/count_merged_prs.py --username ksylvan --repo danielmiessler/fabric'

# libreoffice
alias libreoffice='open -a libreoffice'

function hosts_update() {
    usage_message="Usage: hosts_update <cmd>"
    usage_message+="\n  cmd: fabric, win, brew, appstore, linux, zshrc"
    usage_message+="\n  cmd: all (to run all commands)"
    if [[ $# -eq 0 ]]; then
        echo -e $usage_message
        return 1
    fi

    local cmd="$1"

    local win_hosts=(shakti.local) # Add more Windows hosts here
    local mac_brew_hosts=(dharma.local shiva.local zen.local)
    local mac_appstore_hosts=(dharma.local shiva.local)
    local linux_hosts=(thor.local)
    local zshrc_hosts=(dharma.local thor.local shiva.local zen.local)
    local fabric_hosts=(dharma.local thor.local shakti.local shiva.local zen.local)

    case "$cmd" in
    all)
        for _cmd in fabric win brew appstore linux zshrc; do
            hosts_update $_cmd
        done
        unset _cmd
        ;;
    fabric)
        local _strategies_git="https://github.com/danielmiessler/fabric.git"
        echo "Github sync our fork of fabric first"
        fabric_update
        echo ""
        for _fabric_host in $fabric_hosts; do
            fabric_deploy -url $_strategies_git $_fabric_host
        done
        unset _fabric_host
        ;;
    win)
        for _win_host in $win_hosts; do
            echo "Updating $_win_host"
            ssh $_win_host "scoop update && scoop status"
            echo "Done"
            echo ""
        done
        unset _win_host
        ;;
    brew)
        for _brew_host in $mac_brew_hosts; do
            echo "Updating brew on $_brew_host"
            ssh $_brew_host "source .zprofile && brew update && brew upgrade"
            echo "Done"
            echo ""
        done
        unset _brew_host
        ;;
    appstore)
        for _mas_host in $mac_appstore_hosts; do
            echo "Updating App Store on $_mas_host"
            ssh $_mas_host "source .zprofile && mas upgrade"
            echo "Done"
            echo ""
        done
        unset _mas_host
        ;;
    linux)
        for _linux_host in $linux_hosts; do
            echo "Updating $_linux_host"
            ssh $_linux_host "sudo apt update && sudo apt -y upgrade && sudo snap refresh"
            echo "Done"
            echo ""
        done
        unset _linux_host
        ;;
    zshrc)
        for _zsh_u_host in $zshrc_hosts; do
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
}
