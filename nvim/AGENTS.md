# Neovim Config Guide

- Main config is `init.lua`, kept as one structured file. Add small local helpers near the section that uses them instead of creating new modules.
- Section order is documented at the top of `init.lua`; keep new keymaps in section 4, plugin specs in section 8, and global autocmds in section 9 unless the behavior belongs beside a nearby helper.
- Prefer built-in Neovim APIs and already-installed plugins. Do not add a plugin for behavior that fits in a short autocmd or keymap.
- Image files (`jpg`, `jpeg`, `png`, `svg`) are handled by a `BufReadCmd` autocmd near the Markdown preview helper. It uses `chafa`, `viu`, or `catimg` if installed, and falls back to macOS `qlmanage`.
- Before finishing edits, at minimum run `luac -p nvim/init.lua` or an equivalent Neovim headless load check.
