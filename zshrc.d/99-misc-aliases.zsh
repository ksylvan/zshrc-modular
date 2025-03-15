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

alias zshrc_hosts_update='pssh -H "localhost thor.local shiva.local zen.local" -t 0 -i "cd src/zshrc-modular && git pull && ./install"'
alias brew_hosts_update='pssh -H "localhost shiva.local zen.local" -t 0 -i "source .zprofile && brew update && brew upgrade"'
