#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p plandex-cli &>/dev/null; then
    alias plandex=plandex-cli
    alias pdx=plandex-cli
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "plandex-cli is not installed."
fi
