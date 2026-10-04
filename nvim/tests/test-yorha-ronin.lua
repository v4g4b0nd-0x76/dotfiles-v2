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

local dashboard = Snacks.config.get("dashboard")
assert(type(YorhaRonin.deck_sections) == "function")
assert(type(dashboard.sections) == "table")
assert(dashboard.preset.header:find("YORHA // RONIN", 1, true))
assert(dashboard.preset.header:find("浪人", 1, true))
assert(vim.fn.maparg("<leader>ud", "n") ~= "")

local previous_columns = vim.o.columns
vim.o.columns = 80
local previous_tabs = vim.fn.tabpagenr("$")
assert(pcall(YorhaRonin.open_deck))
assert(vim.bo.filetype == "snacks_dashboard")
assert(vim.fn.tabpagenr("$") == previous_tabs + 1)
assert(vim.fn.maparg("q", "n", false, true).buffer == 1)
vim.cmd("bdelete!")
vim.o.columns = previous_columns
