#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p pnpm &>/dev/null; then
    # Set PNPM_HOME and PATH
    if [[ -d "$HOME/.local/share/pnpm" ]]; then
        export PNPM_HOME=$HOME/.local/share/pnpm
    elif [[ -d "$HOME/Library/pnpm" ]]; then
        export PNPM_HOME=$HOME/Library/pnpm
    else
        export PNPM_HOME=$HOME/.local/share/pnpm
    fi
    [[ " ${path[@]} " != *" $PNPM_HOME "* ]] && path=($PNPM_HOME $path)
    if [[ ${_verbose_loading} -eq 1 ]]; then
        echo "Updated PNPM_HOME: $PNPM_HOME"
        echo "Updated PATH: $PATH"
    fi
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "pnpm is not installed."
fi
