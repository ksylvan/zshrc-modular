#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if [[ -d ~/.local/bin ]]; then
    path=(~/.local/bin $path)
    if [[ ${_verbose_loading} -eq 1 ]]; then
        echo "Added ~/.local/bin to PATH"
    fi
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "~/.local/bin directory does not exist."
fi
true
