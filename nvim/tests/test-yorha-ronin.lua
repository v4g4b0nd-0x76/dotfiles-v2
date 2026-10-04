assert(type(YorhaRonin) == "table", "YorhaRonin HUD must be defined")
assert(vim.o.winbar == "%{%v:lua.YorhaRonin.winbar()%}")

vim.cmd("enew!")
assert(YorhaRonin.relative_file() == "[No Name]")
assert(YorhaRonin.lsp_name() == "")
assert(YorhaRonin.diagnostics() == "")
assert(YorhaRonin.winbar():find("[No Name]", 1, true))
assert(YorhaRonin.session_elapsed():match("^%d%d:%d%d$") ~= nil)

vim.bo.buftype = "nofile"
vim.bo.filetype = "snacks_dashboard"
assert(YorhaRonin.relative_file() == "[snacks_dashboard]")
assert(pcall(YorhaRonin.winbar))
vim.cmd("enew!")
vim.bo.buftype = "help"
vim.bo.filetype = "help"
vim.api.nvim_buf_set_name(0, "help.txt")
assert(YorhaRonin.relative_file() == "[Help: help.txt]")
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
assert(type(navigate[2].action) == "function")
assert(type(navigate[3].action) == "function")
assert(vim.fn.exists(":Telescope") == 2)
assert(vim.wait(100, function()
	return type(require("todo-comments.config").options.search) == "table"
end))
local operate = YorhaRonin.deck_sections()[6]
assert(operate[1].desc == "Git status")
assert(operate[2].desc == "Current file diff")
assert(operate[3].desc == "Browse commits")

local previous_columns = vim.o.columns
vim.o.columns = 80
local previous_tabs = vim.fn.tabpagenr("$")
assert(pcall(YorhaRonin.open_deck))
assert(vim.bo.filetype == "snacks_dashboard")
assert(vim.fn.tabpagenr("$") == previous_tabs + 1)
local rendered_narrow_deck = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
assert(rendered_narrow_deck:find("Find files", 1, true))
assert(rendered_narrow_deck:find("Git status", 1, true))
assert(rendered_narrow_deck:find("Search TODO marks", 1, true))
local close_mapping = vim.fn.maparg("q", "n", false, true)
assert(close_mapping.buffer == 1)
assert(type(close_mapping.callback) == "function")
close_mapping.callback()
assert(vim.fn.tabpagenr("$") == previous_tabs)
vim.o.columns = previous_columns

local telemetry_autocmds = vim.api.nvim_get_autocmds({ group = "YorhaRoninTelemetry" })
assert(#telemetry_autocmds >= 3)

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

local action_sections = YorhaRonin.deck_sections()
action_sections[3][2].action()
assert(vim.bo.filetype == "TelescopePrompt")
require("telescope.actions").close(vim.api.nvim_get_current_buf())
assert(pcall(vim.cmd, "TodoTelescope"))
assert(vim.bo.filetype == "TelescopePrompt")
require("telescope.actions").close(vim.api.nvim_get_current_buf())
action_sections[6][1].action()
assert(vim.bo.filetype == "TelescopePrompt")
require("telescope.actions").close(vim.api.nvim_get_current_buf())
