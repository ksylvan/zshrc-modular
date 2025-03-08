# Set up a colorful prompt with Git branch info

# Use git symbolic-ref to directly get the current branch name.
parse_git_branch() {
    git symbolic-ref --short HEAD 2>/dev/null | sed 's/.*/[&] /'
}

# Define color escape sequences for prompt sections.
COLOR_DEF=$'%f'
COLOR_USR=$'%F{243}'
COLOR_DIR=$'%F{197}'
COLOR_GIT=$'%F{39}'

# Enable substitution in the prompt.
setopt PROMPT_SUBST

# Build the prompt:
# - %n: username
# - %m: hostname
# - %2~: current directory, shortened to show two trailing components
# - $(parse_git_branch): insert the current Git branch (if any)
export PROMPT='${COLOR_USR}%n@%m ${COLOR_DIR}%2~ ${COLOR_GIT}$(parse_git_branch)${COLOR_DEF}$ '
