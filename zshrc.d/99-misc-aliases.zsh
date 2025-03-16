#!/bin/zsh

# Miscellaneous aliases

# Restart tailscale after a brew update
alias tailscale_restart='sudo launchctl kickstart -k system/com.tailscale.tailscaled'

# My PR count so far this month
alias fabric_pr_count='python3 ~/src/backend-tools/count_merged_prs.py --username ksylvan --repo danielmiessler/fabric'

# libreoffice
alias libreoffice='open -a libreoffice'

function zshrc_hosts_update() {
    local hosts=(localhost thor.local shiva.local zen.local)
    for _zsh_u_host in $hosts; do
        echo "Updating zsh startup files for $_zsh_u_host"
        ssh $_zsh_u_host "cd src/zshrc-modular && git pull && ./install"
        echo "Done"
        echo ""
    done
    unset _zsh_u_host
}

alias zshrc_hosts_update='pssh -H "localhost thor.local shiva.local zen.local" -t 0 -i "echo Zshrc update; cd src/zshrc-modular && git pull && ./install"'

alias win_update='ssh shakti.local -t 0 -i "scoop update && scoop status"'

alias brew_hosts_update='pssh -H "localhost shiva.local zen.local" -t 0 -i "echo updating brew; source .zprofile && brew update && brew upgrade"'
alias mac_appstore_update='pssh -H "localhost shiva.local" -t 0 -i "echo App Store update; source .zprofile; mas upgrade"'
alias mac_update='brew_hosts_update && mac_appstore_update'

alias linux_update='ssh thor.local "sudo apt update && sudo apt -y upgrade && sudo snap refresh"'
