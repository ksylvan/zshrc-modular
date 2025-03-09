#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

# Uncomment this to make zshrc loading verbose
# ZSHRC_VERBOSE=1

[[ "${_verbose_loading}" -eq 1 ]] && echo "ZSHRC_VERBOSE set to 1"

unset _verbose_loading
