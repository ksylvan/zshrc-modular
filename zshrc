#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

# Load zprofile if somehow not already loaded
if [[ -z "${__zprofile_loaded}" ]]; then
  [[ $_verbose_loading -eq 1 ]] && echo "Loading zprofile from zshrc"
  for _zprofile_file in "/etc/zprofile" "${HOME}/.zprofile"; do
    if [[ -r "${_zprofile_file}" ]]; then
      [[ $_verbose_loading -eq 1 ]] && echo "Sourcing ${_zprofile_file}"
      source "${_zprofile_file}" ||
        echo "Error: Failed to source ${_zprofile_file}" >&2
    fi
  done
fi

# Load all configuration snippets from ~/.zshrc.d
_zshrc_dir="${HOME}/.zshrc.d"
if [[ -d "${_zshrc_dir}" ]]; then
  # *(.N) glob pattern: match only regular files (.), and don't error if no matches (N)
  for _zshrc_file in "${_zshrc_dir}"/*(.N); do
    if [[ -r "${_zshrc_file}" ]]; then
      [[ $_verbose_loading -eq 1 ]] && echo "Loading ${_zshrc_file}"
      source "${_zshrc_file}" ||
        echo "Error: Failed to source ${_zshrc_file}" >&2
    fi
  done
fi

# Added by LM Studio CLI (lms)
_lmstudio_bin="${HOME}/.lmstudio/bin"
if [[ -d "${_lmstudio_bin}" && ! "$PATH" =~ "${_lmstudio_bin}" ]]; then
  [[ $_verbose_loading -eq 1 ]] && echo "Adding ${_lmstudio_bin} to PATH"
  path+=("${_lmstudio_bin}")
fi

if [[ -r "${HOME}/.iterm2_shell_integration.zsh" ]]; then
  [[ $_verbose_loading -eq 1 ]] && echo "Loading iTerm2 shell integration"
  if ! source "${HOME}/.iterm2_shell_integration.zsh"; then
    echo "Error: Failed to load iTerm2 shell integration" >&2
  fi
fi

# Clean up temporary variables
unset _lmstudio_bin _verbose_loading _zshrc_dir _zshrc_file _zprofile_file
