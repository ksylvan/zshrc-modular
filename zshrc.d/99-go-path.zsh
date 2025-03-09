#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

if whence -p go &>/dev/null; then
    # Set GOPATH and PATH
    export GOPATH=$HOME/go
    [[ " ${path[@]} " != *" $GOPATH/bin "* ]] && path=($GOPATH/bin $path)
    if [[ ${_verbose_loading} -eq 1 ]]; then
        echo "Updated GOPATH: $GOPATH"
        echo "Updated PATH: $PATH"
    fi
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "Go is not installed."
fi

unset _verbose_loading
