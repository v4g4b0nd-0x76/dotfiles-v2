#!/bin/zsh
set -euo pipefail

root=${0:A:h:h}
installer="$root/bin/install-configs.zsh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

is_linked() {
  [[ -L "$1" ]]
  [[ "$(readlink "$1")" == "$2" ]]
}

home="$test_dir/home"
mkdir -p "$home/.config/kitty"
print -r -- 'local kitty config' > "$home/.config/kitty/kitty.conf"

HOME="$home" "$installer"

is_linked "$home/.config/nvim" "$root/nvim"
is_linked "$home/.config/doom" "$root/doom"
is_linked "$home/.config/ghostty" "$root/ghostty"
is_linked "$home/.config/kitty" "$root/kitty"
is_linked "$home/.config/alacritty" "$root/alacritty"
is_linked "$home/.config/sioyek/prefs_user.config" "$root/sioyek/prefs_user.config"
is_linked "$home/.config/spaceship/spaceship.zsh" "$root/zsh/kuro-nezumi.zsh"
is_linked "$home/.zshrc" "$root/.zshrc"
is_linked "$home/.tmux.conf" "$root/.tmux.conf"

backup=$(find "$home/.config/dotfiles-backup" -type f -name kitty.conf -print -quit)
[[ -n "$backup" ]]
[[ "$(<"$backup")" == 'local kitty config' ]]

vault="$test_dir/vault"
mkdir -p "$vault"
HOME="$home" "$installer" --vault "$vault"
is_linked "$vault/.obsidian/themes/Kuro Nezumi" "$root/obsidian/Kuro Nezumi"

mac_home="$test_dir/mac-home"
mkdir -p "$test_dir/bin"
print -r -- '#!/bin/zsh' > "$test_dir/bin/uname"
print -r -- 'print Darwin' >> "$test_dir/bin/uname"
chmod +x "$test_dir/bin/uname"

HOME="$mac_home" PATH="$test_dir/bin:$PATH" "$installer"

is_linked "$mac_home/.aerospace.toml" "$root/aerospace/kuro-hyprland.toml"
is_linked "$mac_home/Library/Application Support/sioyek/prefs_user.config" "$root/sioyek/prefs_user.config"
