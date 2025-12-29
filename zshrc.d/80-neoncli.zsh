#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p neon &>/dev/null; then
    # The following was added to here for neon cli completion
    source <(neon completion zsh)
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "neon is not installed."
fi
true
