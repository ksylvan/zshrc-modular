#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

_brew_ts_path=/opt/homebrew/opt/tailscale

if [[ -d ${_brew_ts_path} ]]; then
    path=(${_brew_ts_path}/bin $path)
    if [[ ${_verbose_loading} -eq 1 ]]; then
        echo "Updated PATH: $PATH"
    fi
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "tailscale is not installed."
fi
unset _brew_ts_path
