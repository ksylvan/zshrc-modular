#!/bin/zsh

_verbose_loading=${ZSHRC_VERBOSE:-0}

# Find Claude CLI
if whence -p claude &>/dev/null; then
    # Make sure there is a .claude/ directory in home
    if [[ ! -d "${HOME}/.claude" ]]; then
        [[ ${_verbose_loading} -eq 1 ]] && echo "Claude exists but no .claude/ directory found. No PAI for you!"
    else
        alias pai='bun run "$HOME"/.claude/skills/CORE/Tools/PAI.ts'
    fi
else
    [[ ${_verbose_loading} -eq 1 ]] && echo "Claude CLI is not installed."
fi

true
