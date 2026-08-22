#!/bin/zsh
# Kuro Nezumi macOS rice
# Preview by default. Use --apply only after reviewing the plan.

emulate -LR zsh
setopt err_return no_unset pipe_fail

if (( EUID == 0 )); then
  print -u2 'Run this as your normal macOS user, not with sudo.'
  exit 1
fi

typeset -r DOTFILES="${0:A:h:h}"
typeset -r HOME_DIR="$HOME"
typeset -r WALLPAPER_DIR="$HOME_DIR/Documents/wallpapers"
typeset -r BLACKENED_WALLPAPER="$WALLPAPER_DIR/kuro-nezumi-musashi-blackened-1920x1080.png"
typeset -r ZEN_WALLPAPER="$WALLPAPER_DIR/kuro-nezumi-zen-samurai-1920x1080.png"
typeset -r MINIMAL_WALLPAPER="$WALLPAPER_DIR/kuro-nezumi-musashi-minimal-1920x1080.png"
typeset -r BACKUP_DIR="$HOME_DIR/.config/kuro-nezumi/backups"

typeset mode='preview'
typeset wallpaper="$BLACKENED_WALLPAPER"
typeset apply_macos=true
typeset apply_links=true

usage() {
  cat <<'USAGE'
Kuro Nezumi macOS rice

Usage:
  kuro-nezumi-rice.zsh [--apply] [--wallpaper blackened|zen|minimal|none]
                         [--only macos|apps] [--help]

Without --apply the script only shows the exact changes it would make.

What --apply does:
  - enables macOS dark appearance and the graphite accent
  - sets one of the Kuro Nezumi wallpapers on every desktop
  - refines Finder, the dark menu bar, Dock, and desktop icon alignment
  - creates missing safe links for Neovim, Sioyek, Obsidian, and Zsh/Spaceship

It never overwrites an existing app config. Chrome/Stylus is intentionally
left manual: a global CSS rule can break individual websites.
USAGE
}

say() { print -P "%F{#9A948A}$*%f"; }
good() { print -P "%F{#8A8F73}ok%f  $*"; }
note() { print -P "%F{#B8A781}::%f  $*"; }
warn() { print -u2 -P "%F{#D94A4A}!%f   $*"; }

run() {
  if [[ "$mode" == preview ]]; then
    note "would run: ${(j: :)${(@q)@}}"
  else
    "$@"
  fi
}

ensure_link() {
  local source_path="$1" target_path="$2" label="$3"

  if [[ ! -e "$source_path" ]]; then
    warn "$label source is missing: $source_path"
    return 0
  fi

  if [[ -L "$target_path" ]]; then
    if [[ "${target_path:A}" == "${source_path:A}" ]]; then
      good "$label already linked"
    else
      warn "$label has a different link; leaving it unchanged: $target_path"
    fi
    return 0
  fi

  if [[ -e "$target_path" ]]; then
    note "$label already has a local config; leaving it unchanged"
    return 0
  fi

  note "$label will link to dotfiles"
  run mkdir -p "${target_path:h}"
  run ln -s "$source_path" "$target_path"
}

set_macos_appearance() {
  note 'macOS appearance: dark mode + graphite accent'
  if [[ "$mode" == preview ]]; then
    note 'would enable dark appearance, set graphite accent, and use a muted gray selection color'
  else
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
    defaults write -g AppleAccentColor -int -1
    defaults write -g AppleHighlightColor -string '0.50 0.50 0.50'
  fi
}

set_workspace_chrome() {
  local finder_plist="$HOME_DIR/Library/Preferences/com.apple.finder.plist"
  local backup_file="$BACKUP_DIR/com.apple.finder.$(date +%Y%m%d-%H%M%S).plist"

  note 'workspace chrome: Finder, dark menu bar, Dock, and desktop icon grid'
  if [[ "$mode" == preview ]]; then
    note 'would use a 52px Dock, 72px magnification, and the quieter scale animation'
    note 'would make the dark menu bar solid, keep Finder in column view, and show its path/status bars'
    note 'would back up Finder preferences, then use 64px desktop icons on an 80px snap-to-grid layout'
    note 'would restart Finder and Dock so the new chrome appears immediately'
    return 0
  fi

  defaults write -g AppleEnableMenuBarTransparency -bool false
  defaults write com.apple.dock orientation -string 'bottom'
  defaults write com.apple.dock tilesize -int 52
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock largesize -int 72
  defaults write com.apple.dock mineffect -string 'scale'

  defaults write com.apple.finder FXPreferredViewStyle -string 'clmv'
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder AppleShowAllExtensions -bool true

  if [[ -f "$finder_plist" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$finder_plist" "$backup_file"
    good "Finder preferences backed up: $backup_file"

    /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:arrangeBy grid' "$finder_plist"
    /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:gridSpacing 80' "$finder_plist"
    /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:iconSize 64' "$finder_plist"
    /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:textSize 11' "$finder_plist"
    /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:labelOnBottom true' "$finder_plist"
    /usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:showItemInfo false' "$finder_plist"
  else
    warn "Finder preference file was not found; skipped desktop icon alignment"
  fi

  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
}

set_wallpaper() {
  if [[ "$wallpaper" == none ]]; then
    note 'wallpaper: unchanged'
    return 0
  fi

  if [[ ! -f "$wallpaper" ]]; then
    warn "wallpaper is missing: $wallpaper"
    return 0
  fi

  note "wallpaper: ${wallpaper:t}"
  if [[ "$mode" == preview ]]; then
    note 'would set this wallpaper on every macOS desktop'
  else
    osascript - "$wallpaper" <<'APPLESCRIPT'
on run argv
  tell application "System Events"
    tell every desktop to set picture to POSIX file (item 1 of argv)
  end tell
end run
APPLESCRIPT
  fi
}

apply_app_links() {
  note 'app configuration links'
  ensure_link "$DOTFILES/nvim" "$HOME_DIR/.config/nvim" 'Neovim'
  ensure_link "$DOTFILES/sioyek/prefs_user.config" "$HOME_DIR/Library/Application Support/sioyek/prefs_user.config" 'Sioyek'
  ensure_link "$DOTFILES/obsidian/Kuro Nezumi" "$HOME_DIR/Desktop/notes/.obsidian/themes/Kuro Nezumi" 'Obsidian notes theme'
  ensure_link "$DOTFILES/obsidian/Kuro Nezumi" "$HOME_DIR/Desktop/study/.obsidian/themes/Kuro Nezumi" 'Obsidian study theme'
  ensure_link "$DOTFILES/zsh/kuro-nezumi.zsh" "$HOME_DIR/.config/spaceship/spaceship.zsh" 'Zsh / Spaceship'

  if [[ -e "$HOME_DIR/.config/ghostty/config" ]]; then
    good 'Ghostty config already exists (kept untouched)'
  else
    ensure_link "$DOTFILES/ghostty/config" "$HOME_DIR/.config/ghostty/config" 'Ghostty'
  fi

  if [[ -f "$HOME_DIR/Library/Preferences/calibre/viewer-webengine.json" ]]; then
    good 'Calibre reader preferences found (kept untouched)'
  else
    note 'Calibre has no local reader preferences yet; open a book once, then apply the Kuro Nezumi scheme in Calibre'
  fi

  note 'Chrome: keep the Kuro Nezumi Stylus stylesheet scoped to selected domains; it is not applied globally on purpose'
}

while (( $# )); do
  case "$1" in
    --apply)
      mode='apply'
      ;;
    --wallpaper)
      shift
      (( $# )) || { warn '--wallpaper needs blackened, zen, minimal, or none'; exit 2; }
      case "$1" in
        blackened) wallpaper="$BLACKENED_WALLPAPER" ;;
        zen) wallpaper="$ZEN_WALLPAPER" ;;
        minimal) wallpaper="$MINIMAL_WALLPAPER" ;;
        none) wallpaper='none' ;;
        *) warn "unknown wallpaper choice: $1"; exit 2 ;;
      esac
      ;;
    --only)
      shift
      (( $# )) || { warn '--only needs macos or apps'; exit 2; }
      case "$1" in
        macos) apply_links=false ;;
        apps) apply_macos=false ;;
        *) warn "unknown scope: $1"; exit 2 ;;
      esac
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      warn "unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

print -P "%F{#D94A4A}KURO NEZUMI%f %F{#6F6A63}// macOS rice //%f %F{#D7D2C8}$mode%f"
say 'black / ash / warm paper / signal red'

if [[ "$apply_macos" == true ]]; then
  set_macos_appearance
  set_wallpaper
  set_workspace_chrome
fi

if [[ "$apply_links" == true ]]; then
  apply_app_links
fi

if [[ "$mode" == preview ]]; then
  print
  note "reviewed? apply with: ${0:A} --apply"
else
  print
  good 'rice applied — reopen Ghostty, Obsidian, Sioyek, and Calibre to refresh their appearance'
fi
