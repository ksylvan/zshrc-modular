# pbpaste/pbcopy for Linux

_verbose_loading=${ZSHRC_VERBOSE:-0}

_zshrc_host_type=$(uname -s)

if [[ ${_zshrc_host_type} == 'Linux' ]]; then
  has() { command -v "$1" >/dev/null 2>&1; }
  
  pbcopy() {
    if [ -n "$WAYLAND_DISPLAY" ] && has wl-copy; then
      wl-copy
    elif has xclip; then
      xclip -selection clipboard
    elif has xsel; then
      xsel --clipboard --input
    else
      printf "Please install wl-clipboard or xclip/xsel\n" >&2; return 1
    fi
  }
  
  pbpaste() {
    if [[ -n "$WAYLAND_DISPLAY" ]] && has wl-paste; then
      wl-paste
    elif has xclip; then
      xclip -selection clipboard -o
    elif has xsel; then
      xsel --clipboard --output
    else
      printf "Install wl-clipboard or xclip/xsel\n" >&2; return 1
    fi
  }
fi

unset _zshrc_host_type
