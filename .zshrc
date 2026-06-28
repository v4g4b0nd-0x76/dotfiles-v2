export ZSH="$HOME/.oh-my-zsh"


plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="1000"
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_THEME="spaceship"

SPACESHIP_PROMPT_ASYNC=true

SPACESHIP_PROMPT_ORDER=(
  time
  user
  dir
  git
  line_sep
  char
)
DISABLE_LS_COLORS="true"


source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"
export PATH="$PATH:/usr/local/bin/nvim/bin"
export PATH=$PATH:/usr/local/go/bin
export GOROOT=$HOME/go
