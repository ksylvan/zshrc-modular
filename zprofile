#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}
_brew_found=0

# Check common Homebrew installation paths
for _brew_path in /usr/local/bin/brew /opt/homebrew/bin/brew; do
    if [[ -x "$_brew_path" && -f "$_brew_path" ]]; then
        [[ "${_verbose_loading}" -eq 1 ]] &&
            echo "Homebrew binary exists: ${_brew_path}"
        eval "$($_brew_path shellenv)"
        _brew_found=1
        break
    fi
done

if [[ $_brew_found -eq 0 ]]; then
    [[ "${_verbose_loading}" -eq 1 ]] && echo "Warning: Homebrew not found in standard locations"
fi

# Clean up script-local variables
unset _brew_found _brew_path _verbose_loading
