#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
XDG_CONFIG_HOME="$root/.." XDG_STATE_HOME=/tmp/dotfiles-nvim-state XDG_CACHE_HOME=/tmp/dotfiles-nvim-cache \
	nvim --headless -u "$root/init.lua" \
	'+lua local a = pcall(require, "lualine"); local b = pcall(require, "snacks"); local c = pcall(require, "todo-comments"); local d = vim.fn.maparg("<C-_>", "n") ~= ""; local e = Snacks.config.get("scroll").enabled == false; if not (a and b and c and d and e) then vim.cmd("cquit 1") end' \
	'+lua if vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg ~= 0x121110 then vim.cmd("cquit 1") end' \
	"+lua local ok, err = pcall(dofile, '$root/tests/test-yorha-ronin.lua'); if not ok then io.stderr:write(err .. '\\n'); vim.cmd('cquit 1') end" \
	'+lua local dashboard = Snacks.config.get("dashboard") or {}; local header = dashboard.preset and dashboard.preset.header; if not (header and header:find("YORHA // RONIN", 1, true)) then vim.cmd("cquit 1") end' \
	"+lua local ok, err = pcall(dofile, '$root/tests/test-boundaries.lua'); if not ok then io.stderr:write(err .. '\\n'); vim.cmd('cquit 1') end" \
	"+lua local ok, err = pcall(dofile, '$root/tests/test-runner.lua'); if not ok then io.stderr:write(err .. '\\n'); vim.cmd('cquit 1') end" \
	'+qa!'
