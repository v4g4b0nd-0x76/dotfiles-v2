#!/bin/zsh
set -euo pipefail

script=${0:A:h:h}/bin/kuro-nezumi-rice.zsh
output=$($script --hyprland --wallpaper none)

[[ $output == *'Hyprland-like workspace: preview only'* ]]
[[ $output == *'would back up AeroSpace, apply the four-workspace profile'* ]]
[[ $output == *'reviewed? apply with:'* ]]
[[ $output != *'app configuration links'* ]]

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/home"
for command_name in osascript killall aerospace; do
  print -r -- '#!/bin/zsh' > "$test_dir/bin/$command_name"
  print -r -- 'exit 0' >> "$test_dir/bin/$command_name"
  chmod +x "$test_dir/bin/$command_name"
done
{
  print -r -- '#!/bin/zsh'
  print -r -- 'if [[ $1 == export ]]; then'
  print -r -- '  mkdir -p ${3:h}'
  print -r -- '  : > "$3"'
  print -r -- 'fi'
  print -r -- 'exit 0'
} > "$test_dir/bin/defaults"
chmod +x "$test_dir/bin/defaults"

output=$(PATH="$test_dir/bin:$PATH" HOME="$test_dir/home" $script --apply --hyprland --wallpaper none)
[[ $output != *'Hyprland-like workspace: preview only'* ]]
[[ $output == *'Hyprland-like workspace applied'* ]]
[[ -f "$test_dir/home/.aerospace.toml" ]]
