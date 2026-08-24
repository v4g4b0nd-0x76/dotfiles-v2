#!/bin/zsh
# Build and apply reversible Kuro Nezumi Finder icons for selected applications.
# Ghostty is intentionally excluded: it manages its Dock icon at runtime through
# its native `macos-icon` setting in the Ghostty config.

emulate -LR zsh
setopt err_return no_unset pipe_fail

typeset -r DOTFILES="${0:A:h:h}"
typeset -r ICON_ROOT="$DOTFILES/icons/kuro-nezumi"
typeset -r BUILD_ROOT="$ICON_ROOT/build"
typeset mode='build'
typeset -a selected_names=()
typeset -a active_names=()

usage() {
  cat <<'USAGE'
Usage: kuro-nezumi-icons.zsh [--build|--apply|--restore] [--only app]

  --build    create .icns files from the Kuro source artwork (default)
  --apply    build and set reversible custom Finder icons on supported apps
  --restore  remove only the custom Finder icons, restoring each app's own icon
  --only     limit the action to chrome, spotify, windscribe, chatgpt, or obsidian

Safari is excluded because it is a protected macOS application.
Ghostty is excluded because its Dock icon is configured natively in Ghostty.
Apps in /Applications may require an explicit admin run and App Management permission
for the terminal application that runs this script: sudo $0 --apply
USAGE
}

note() { print -P "%F{#B8A781}::%f  $*"; }
good() { print -P "%F{#8A8F73}ok%f  $*"; }
warn() { print -u2 -P "%F{#D94A4A}!%f   $*"; }

typeset -A icon_sources app_paths
icon_sources=(
  chrome "$ICON_ROOT/chrome.svg"
  spotify "$ICON_ROOT/spotify.svg"
  windscribe "$ICON_ROOT/windscribe.svg"
  chatgpt "$ICON_ROOT/chatgpt.svg"
  obsidian "$ICON_ROOT/obsidian.svg"
)
app_paths=(
  chrome '/Applications/Google Chrome.app'
  spotify '/Applications/Spotify.app'
  windscribe '/Applications/Windscribe.app'
  chatgpt '/Applications/ChatGPT.app'
  obsidian '/Applications/Obsidian.app'
)

build_icon() {
  local name="$1" source_image="${icon_sources[$1]}"
  local iconset="$BUILD_ROOT/$name.iconset" output="$BUILD_ROOT/$name.icns"
  local -a sizes=(16 32 64 128 256 512 1024)
  local size file_name

  [[ -r "$source_image" ]] || { warn "missing icon source: $source_image"; return 1; }
  mkdir -p "$iconset"

  for size in $sizes; do
    case "$size" in
      16) file_name='icon_16x16.png' ;;
      32) file_name='icon_16x16@2x.png' ;;
      64) file_name='icon_32x32@2x.png' ;;
      128) file_name='icon_128x128.png' ;;
      256) file_name='icon_128x128@2x.png' ;;
      512) file_name='icon_512x512.png' ;;
      1024) file_name='icon_512x512@2x.png' ;;
    esac
    sips -s format png -z "$size" "$size" "$source_image" --out "$iconset/$file_name" >/dev/null
  done

  iconutil -c icns "$iconset" -o "$output"
  good "built ${output:t}"
}

build_all() {
  mkdir -p "$BUILD_ROOT"
  local name
  for name in "${active_names[@]}"; do
    build_icon "$name"
  done
}

apply_all() {
  (( $+commands[fileicon] )) || {
    warn 'fileicon is required once to apply the icons.'
    warn 'Install it with: brew install fileicon'
    return 1
  }

  local name app_path icon_path applied=0
  for name in "${active_names[@]}"; do
    app_path="${app_paths[$name]}"
    icon_path="$BUILD_ROOT/$name.iconset/icon_512x512@2x.png"
    if [[ -d "$app_path" ]]; then
      if fileicon set "$app_path" "$icon_path"; then
        # Touch the bundle so LaunchServices and Dock reconsider the custom icon.
        touch "$app_path"
        good "applied ${name}"
        applied=1
      else
        warn "could not change ${name}; allow your terminal in Privacy & Security > App Management, then retry"
      fi
    else
      note "skipped ${name}; app is not installed"
    fi
  done
  (( applied )) && killall Dock 2>/dev/null || true
}

restore_all() {
  (( $+commands[fileicon] )) || {
    warn 'fileicon is required to restore custom icons.'
    return 1
  }

  local name app_path
  for name in "${active_names[@]}"; do
    app_path="${app_paths[$name]}"
    [[ -d "$app_path" ]] || continue
    fileicon rm "$app_path" 2>/dev/null || true
    # fileicon can leave an empty custom-icon marker behind; remove only that marker.
    if xattr -d com.apple.FinderInfo "$app_path" 2>/dev/null; then
      good "restored ${name}"
    else
      warn "could not restore ${name}; allow your terminal in Privacy & Security > App Management, then retry"
    fi
  done
  killall Dock 2>/dev/null || true
}

while (( $# )); do
  case "$1" in
    --build|--apply|--restore)
      mode="${1#--}"
      ;;
    --only)
      shift
      (( $# )) || { warn '--only needs an app name'; exit 2; }
      (( ${+app_paths[$1]} )) || { warn "unknown app: $1"; exit 2; }
      selected_names+=("$1")
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

if (( ${#selected_names} )); then
  active_names=("${selected_names[@]}")
else
  active_names=("${(@k)app_paths}")
fi

case "$mode" in
  build)
    build_all
    ;;
  apply)
    build_all
    apply_all
    ;;
  restore)
    restore_all
    ;;
esac
