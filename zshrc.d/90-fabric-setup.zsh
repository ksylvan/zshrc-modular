#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}
_fabric_available=false

if whence -p fabric &>/dev/null; then
    _fabric_available=true
    [[ ${_verbose_loading} -eq 1 ]] && echo "fabric is installed."
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "fabric is not installed."
    if whence -p fabric-ai &>/dev/null; then
        _fabric_available=true
        [[ ${_verbose_loading} -eq 1 ]] && echo "fabric-ai is installed, creating alias."
        alias fabric='fabric-ai'
    fi
fi

FABRIC_ALIAS_PREFIX="f_"
FABRIC_BOOTSTRAP="$HOME/.config/fabric/fabric-bootstrap.inc"

if [[ -f "$FABRIC_BOOTSTRAP" && $_fabric_available = true ]]; then
    [[ ${_verbose_loading} -eq 1 ]] && echo "Sourcing fabric bootstrap file: $FABRIC_BOOTSTRAP"
    source "$FABRIC_BOOTSTRAP"
fi

unset _fabric_available
unset FABRIC_BOOTSTRAP
unset FABRIC_ALIAS_PREFIX
