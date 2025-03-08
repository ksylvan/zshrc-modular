# Miscellaneous aliases

# Restart tailscale after a brew update
alias tailscale_restart='sudo launchctl kickstart -k system/com.tailscale.tailscaled'

# My PR count so far this month
alias fabric_pr_count='python3 ~/src/backend-tools/count_merged_prs.py --username ksylvan --repo danielmiessler/fabric'

# libreoffice
alias libreoffice='open -a libreoffice'

alias fabric_hosts_update='fabric_update; fabric_deploy localhost shakti.local shiva.local zen.local'
