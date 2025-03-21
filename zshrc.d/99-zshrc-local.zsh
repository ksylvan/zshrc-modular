#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if [[ -f "$HOME/.zshrc.local" ]]; then
    [[ $_verbose_loading -eq 1 ]] && echo "Loading $HOME/.zshrc.local"
    source "$HOME/.zshrc.local" || echo "Error: Failed to source $HOME/.zshrc.local" >&2
else
    [[ $_verbose_loading -eq 1 ]] && echo "No $HOME/.zshrc.local file found"
fi
