# Locate the directory containing compinit (only the first match)
compinit_dir="$(dirname "$(find /usr/share/zsh -name compinit -print -quit)")"

# Prepend the compinit directory and a custom completion directory to fpath
fpath=("$compinit_dir" "$HOME/.zsh/completion" "${fpath[@]}")
unset compinit_dir

# Enable zsh and Bash completion systems
autoload -Uz compinit bashcompinit
compinit
bashcompinit
