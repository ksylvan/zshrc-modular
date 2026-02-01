#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p bun &>/dev/null; then
    # Set PATH
    if [[ -d "$HOME/.bun/bin" ]]; then
        [[ " ${path[@]} " != *" $HOME/.bun/bin "* ]] && path=($HOME/.bun/bin $path)
        [[ ${_verbose_loading} -eq 1 ]] && echo "Updated PATH: $PATH"
    fi
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "bun is not installed."
fi
true
