
#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

[[ $_verbose_loading -eq 1 ]] && echo "Warpifying..."

# Auto-Warpify
[[ "$-" == *i* ]] && printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\x9c'
