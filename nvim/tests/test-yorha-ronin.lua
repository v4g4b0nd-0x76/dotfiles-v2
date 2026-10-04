assert(type(YorhaRonin) == "table", "YorhaRonin HUD must be defined")
assert(vim.o.winbar == "%{%v:lua.YorhaRonin.winbar()%}")

vim.cmd("enew!")
assert(YorhaRonin.relative_file() == "[No Name]")
assert(YorhaRonin.lsp_name() == "")
assert(YorhaRonin.diagnostics() == "")
assert(YorhaRonin.winbar():find("[No Name]", 1, true))
assert(YorhaRonin.session_elapsed():match("^%d%d:%d%d$") ~= nil)

vim.bo.buftype = "nofile"
assert(pcall(YorhaRonin.winbar))
vim.cmd("enew!")
vim.bo.buftype = "help"
vim.bo.filetype = "help"
assert(pcall(YorhaRonin.winbar))
vim.cmd("enew!")

local signal = vim.api.nvim_get_hl(0, { name = "YorhaSignal", link = false })
assert(signal.fg == 0xf75341)
vim.api.nvim_set_hl(0, "YorhaSignal", {})
vim.api.nvim_exec_autocmds("ColorScheme", {})
assert(vim.api.nvim_get_hl(0, { name = "YorhaSignal", link = false }).fg == 0xf75341)

local lualine = require("lualine").get_config()
assert(lualine.options.globalstatus == true)
assert(lualine.options.section_separators.left == "")
