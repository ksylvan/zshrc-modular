#!/bin/zsh

# Load all configuration snippets from ~/.zshrc.d
_zshrc_dir="${HOME}/.zshrc.d"
if [[ -d "${_zshrc_dir}" ]]; then
  for _zshrc_file in "${_zshrc_dir}"/*(.N); do
    if [[ -r "${_zshrc_file}" && -f "${_zshrc_file}" ]]; then
      source "${_zshrc_file}"
    fi
  done
fi
unset _zshrc_dir _zshrc_file

# Added by LM Studio CLI (lms)
if [[ -d "${HOME}/.lmstudio/bin" && ! $PATH =~ ${HOME}/.lmstudio/bin ]]; then
  export PATH="$PATH:${HOME}/.lmstudio/bin"
fi

[[ -r "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"
