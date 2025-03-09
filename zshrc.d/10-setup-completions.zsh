#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

# Start with existing fpath
_custom_fpath=("${fpath[@]}")

if [[ -d /usr/share/zsh ]]; then
    # Locate the directory containing compinit (we want only the first match)
    setopt nullglob
    _compinit_files=(/usr/share/zsh/**/compinit)
    unsetopt nullglob

    if [[ -n "$_compinit_files" ]]; then
        _compinit_file="${_compinit_files[1]}"
        _compinit_dir=${_compinit_file%/*}
        [[ "${_verbose_loading}" -eq 1 ]] && echo "Found compinit file ${_compinit_file}"
    else
        echo "Warning: compinit file not found in /usr/share/zsh" >&2
        _compinit_dir=""
    fi
else
    echo "Warning: /usr/share/zsh directory not found. Using default completion paths." >&2
    _compinit_dir=""
fi

# custom completions directory
mkdir -p "${HOME}/.zsh/completion"

# Always add the custom completion directory
_custom_fpath=("$HOME/.zsh/completion" "${_custom_fpath[@]}")
[[ "${_verbose_loading}" -eq 1 ]] &&
    echo "Added to fpath: custom completion dir ${HOME}/.zsh/completion"

# Add compinit directory if valid
if [[ -n "$_compinit_dir" && -d "$_compinit_dir" ]]; then
    _custom_fpath=("${_compinit_dir}" "${_custom_fpath[@]}")
    [[ "${_verbose_loading}" -eq 1 ]] && echo "Added to fpath: compinit dir ${_compinit_dir}"
fi

# Update fpath
fpath=("${_custom_fpath[@]}")

# Enable zsh and Bash completion systems
if autoload -Uz compinit bashcompinit; then
    compinit
    bashcompinit
else
    echo "Error: autoload of compinit and bashcompinit failed."
fi
unset _compinit_dir _compinit_file _compinit_files _custom_fpath
