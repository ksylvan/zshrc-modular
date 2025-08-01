#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p thefuck &>/dev/null; then
    eval $(thefuck --alias)
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "thefuck is not installed."
fi
true
