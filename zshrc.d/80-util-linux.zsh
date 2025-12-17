#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p brew &>/dev/null; then
    if brew list | grep -q 'util-linux' &>/dev/null; then
        [[ ${_verbose_loading} -eq 1 ]] && echo "util-linux is installed. Setting path..."
        _zsh_util_linux_prefix="$(brew --prefix util-linux)"
        if [[ -d "${_zsh_util_linux_prefix}/bin" ]]; then
            [[ " ${path[@]} " != *" ${_zsh_util_linux_prefix}/bin "* ]] && path=("${_zsh_util_linux_prefix}/bin" $path)
            [[ ${_verbose_loading} -eq 1 ]] && echo "Updated PATH: $PATH"
        fi
        unset _zsh_util_linux_prefix
    fi
fi
true
