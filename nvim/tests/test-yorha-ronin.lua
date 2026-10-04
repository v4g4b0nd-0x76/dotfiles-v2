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
local navigate = YorhaRonin.deck_sections()[3]
assert(navigate[1].action == "<leader>ff")
assert(navigate[2].action == "<leader>fg")
assert(type(navigate[3].action) == "function")

local previous_columns = vim.o.columns
vim.o.columns = 80
local previous_tabs = vim.fn.tabpagenr("$")
assert(pcall(YorhaRonin.open_deck))
assert(vim.bo.filetype == "snacks_dashboard")
assert(vim.fn.tabpagenr("$") == previous_tabs + 1)
assert(vim.fn.maparg("q", "n", false, true).buffer == 1)
vim.cmd("bdelete!")
vim.o.columns = previous_columns

vim.cmd("enew!")
local diagnostic_namespace = vim.api.nvim_create_namespace("yorha_ronin_test")
vim.diagnostic.set(diagnostic_namespace, 0, {
	{ lnum = 0, col = 0, message = "error", severity = vim.diagnostic.severity.ERROR },
	{ lnum = 0, col = 1, message = "warning", severity = vim.diagnostic.severity.WARN },
})
assert(YorhaRonin.diagnostics() == "E:1 W:1")
vim.diagnostic.reset(diagnostic_namespace, 0)

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
local old_path = vim.env.PATH
local old_notify = vim.notify
local notifications = 0
vim.notify = function()
	notifications = notifications + 1
end
vim.env.PATH = ""
assert(YorhaRonin.git_summary(tmp) == "")
assert(YorhaRonin.todo_count(tmp) == "")
YorhaRonin.refresh_telemetry(tmp)
assert(YorhaRonin.todo_status() == "")
assert(YorhaRonin.session_available(tmp) == false)
vim.fn.writefile({ "let g:yorha_session_test = 1" }, tmp .. "/.nvim_session")
assert(YorhaRonin.session_available(tmp) == true)
assert(type(YorhaRonin.telemetry_items()) == "table")
assert(notifications == 0)
local old_cwd = vim.fn.getcwd()
vim.fn.chdir(tmp)
assert(pcall(YorhaRonin.open_deck))
local rendered_deck = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
assert(rendered_deck:find(vim.fn.fnamemodify(tmp, ":t"), 1, true))
vim.cmd("tabclose!")
vim.fn.chdir(old_cwd)
vim.env.PATH = old_path
vim.notify = old_notify
vim.fn.delete(tmp, "rf")
