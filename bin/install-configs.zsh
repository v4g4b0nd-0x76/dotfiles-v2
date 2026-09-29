#!/bin/zsh
# Link this checkout's portable app configs into the current user's home directory.
emulate -LR zsh
setopt err_return no_unset pipe_fail

typeset -r DOTFILES="${0:A:h:h}"
typeset -r CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
typeset -r BACKUP_HOME="$CONFIG_HOME/dotfiles-backup"
typeset vault=''

usage() {
  print 'Usage: install-configs.zsh [--vault /path/to/obsidian-vault]'
}

while (( $# )); do
  case "$1" in
    --vault)
      (( $# >= 2 )) || { print -u2 -- '--vault needs a vault path'; exit 2; }
      vault="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      print -u2 -- "unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

link_config() {
  local source="$1" target="$2" backup

  [[ -e "$source" || -L "$source" ]] || {
    print -u2 -- "missing dotfiles source: $source"
    return 1
  }
  if [[ -L "$target" && "${target:A}" == "${source:A}" ]]; then
    print -- "linked: ${target#$HOME/}"
    return
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$BACKUP_HOME/${target#$HOME/}"
    [[ -e "$backup" || -L "$backup" ]] && backup+=".$(date +%Y%m%d-%H%M%S)"
    mkdir -p "${backup:h}"
    mv "$target" "$backup"
    print -- "backed up: ${target#$HOME/} -> ${backup#$HOME/}"
  fi
  mkdir -p "${target:h}"
  ln -s "$source" "$target"
  print -- "linked: ${target#$HOME/}"
}

link_config "$DOTFILES/nvim" "$CONFIG_HOME/nvim"
link_config "$DOTFILES/doom" "$CONFIG_HOME/doom"
link_config "$DOTFILES/ghostty" "$CONFIG_HOME/ghostty"
link_config "$DOTFILES/kitty" "$CONFIG_HOME/kitty"
link_config "$DOTFILES/alacritty" "$CONFIG_HOME/alacritty"
link_config "$DOTFILES/zsh/kuro-nezumi.zsh" "$CONFIG_HOME/spaceship/spaceship.zsh"
link_config "$DOTFILES/.zshrc" "$HOME/.zshrc"
link_config "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"

case "$(uname -s)" in
  Darwin)
    link_config "$DOTFILES/sioyek/prefs_user.config" "$HOME/Library/Application Support/sioyek/prefs_user.config"
    link_config "$DOTFILES/aerospace/kuro-hyprland.toml" "$HOME/.aerospace.toml"
    ;;
  Linux)
    link_config "$DOTFILES/sioyek/prefs_user.config" "$CONFIG_HOME/sioyek/prefs_user.config"
    ;;
  *)
    print -u2 -- "Sioyek skipped: unsupported system $(uname -s)"
    ;;
esac

if [[ -n "$vault" ]]; then
  [[ -d "$vault" ]] || { print -u2 -- "Obsidian vault does not exist: $vault"; exit 2; }
  link_config "$DOTFILES/obsidian/Kuro Nezumi" "$vault/.obsidian/themes/Kuro Nezumi"
fi

print -- 'Browser and Calibre themes need manual import; see browser/README.md and calibre/kuro-nezumi.css.'
