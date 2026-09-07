#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
XDG_CONFIG_HOME="$root/.." XDG_STATE_HOME=/tmp/dotfiles-nvim-state XDG_CACHE_HOME=/tmp/dotfiles-nvim-cache \
	nvim --headless -u "$root/init.lua" \
	'+lua local a = pcall(require, "lualine"); local b = pcall(require, "snacks"); local c = pcall(require, "todo-comments"); local d = vim.fn.maparg("<C-_>", "n") ~= ""; local e = Snacks.config.get("scroll").enabled == false; if not (a and b and c and d and e) then vim.cmd("cquit 1") end' \
	'+lua local dashboard = Snacks.config.get("dashboard") or {}; local header = dashboard.preset and dashboard.preset.header; if not (header and header:find("|___|", 1, true)) then vim.cmd("cquit 1") end' \
	"+luafile $root/tests/test-boundaries.lua" \
	'+qa!'
