#!/bin/zsh

# Miscellaneous aliases

# Restart tailscale after a brew update
alias tailscale_restart='sudo launchctl kickstart -k system/com.tailscale.tailscaled'

# My PR count so far this month
alias fabric_pr_count='python3 ~/src/backend-tools/count_merged_prs.py --username ksylvan --repo danielmiessler/fabric'

# libreoffice
alias libreoffice='open -a libreoffice'

alias fabric_hosts_update='fabric_update; fabric_deploy localhost thor.local shakti.local shiva.local zen.local'
function zshrc_hosts_update() {
    local hosts=(localhost thor.local shiva.local zen.local)
    for _zsh_u_host in $hosts; do
        ssh $_zsh_u_host "cd src/zshrc-modular && git pull && ./install"
    done
    unset _zsh_u_host
}
