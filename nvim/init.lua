-- ========================================================================== --
-- [[                        STRUCTURED NVIM CONFIG                        ]] --
-- ==========================================================================--
-- Sections:
--   1. Base options & performance
--   2. Highlight groups (diagnostics, winbar, splits, multicursor)
--   3. Winbar (per-split identifier)
--   4. Global keymaps (navigation, sessions, diagnostics, indenting, git, registers)
--   5. Markdown / notes quality-of-life
--   6. Lazy.nvim bootstrap
--   7. LSP on_attach
--   8. Plugin specs
--   9. Autocommands (LSP health/cleanup, terminal, sessions, focus helper)
--  10. Project management (save/list/delete projects, JSON-backed)
-- ========================================================================== --

-- ========================================================================== --
-- 1. BASE OPTIONS & PERFORMANCE
-- ========================================================================== --
vim.g.mapleader = " "

-- Disable unused providers -> faster startup, no python/ruby/node health checks
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Fix: `cd A && nvim B/main.rs` left the working directory at A (the shell's
-- cwd nvim was launched from), not at B. Since nvim-tree, telescope, and
-- `getcwd()`-based project logic all key off the working directory, that
-- made nvim-tree open showing A's entries instead of B's, even though the
-- buffer itself was clearly under B. This runs synchronously before any
-- plugin loads: if a file/dir was passed on the command line, jump the cwd
-- to its git root (or its own directory if no .git is found upward), so
-- everything downstream (nvim-tree, telescope, the project keymaps below,
-- session sourcing) is rooted where the file actually lives.
do
	local first_arg = vim.fn.argv(0)
	if type(first_arg) == "string" and first_arg ~= "" then
		local target = vim.fn.fnamemodify(first_arg, ":p")
		local dir = (vim.fn.isdirectory(target) == 1) and target or vim.fn.fnamemodify(target, ":h")
		local root = vim.fs.root(dir, { ".git" }) or dir
		pcall(vim.fn.chdir, root)
	end
end

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"
opt.updatetime = 250 -- snappier diagnostics/gitsigns/CursorHold without being wasteful
opt.timeoutlen = 400 -- which-key popup appears quickly
opt.ttimeoutlen = 10
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.equalalways = false
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.hidden = true
opt.autowrite = true
opt.laststatus = 3 -- ONE global statusline at the very bottom (lualine uses this too)
opt.fillchars = { vert = "│", eob = " " } -- cleaner vertical split separators

-- Ghostty uses an extensionless `config` file, so Neovim cannot infer its
-- syntax by filename alone. Treat it as a standard key/value config file to
-- retain the Kuro Nezumi syntax colors when editing terminal settings.
vim.filetype.add({
	pattern = {
		[".*/ghostty/config"] = "conf",
		[".*/ghostty/config%.ghostty"] = "conf",
	},
})

-- Keep diagnostics useful without turning the editor into a wall of noise.
-- Deep LSP diagnostics are shown in the sign column and at the end of the
-- affected line; the full message remains one keystroke away with `K`.
vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	update_in_insert = false,
	virtual_text = { spacing = 3, prefix = "●", source = "if_many" },
	float = { border = "rounded", source = "if_many", severity_sort = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.INFO] = "●",
			[vim.diagnostic.severity.HINT] = "●",
		},
	},
})

-- ========================================================================== --
-- 2. HIGHLIGHT GROUPS
-- ========================================================================== --
vim.api.nvim_set_hl(0, "DiagnosticLineNrError", { fg = "#f38ba8", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrWarn", { fg = "#fab387", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrInfo", { fg = "#89b4fa", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrHint", { fg = "#a6adc8", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#f38ba8", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#fab387", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#89b4fa", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#a6adc8", italic = true })

-- Winbar - Neovim uses "WinBar" for the focused split and "WinBarNC" for
-- every other split automatically, so styling these two groups is enough
-- to make each split visually distinct.
vim.api.nvim_set_hl(0, "WinBar", { fg = "#1e1e2e", bg = "#a6adc8", bold = true })
vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#6c7086", bg = "NONE", italic = true })
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#a6adc8", bold = true })

-- Multicursor selections: the plugin's default is a dark reverse-video
-- block, which is what you were calling "not cool". These two groups are
-- the only ones multicursors.nvim exposes, so overriding them is enough
-- to get a light, readable highlight for every selection.
vim.api.nvim_set_hl(0, "MultiCursor", { bg = "#f9e2af", fg = "#1e1e2e" })
vim.api.nvim_set_hl(0, "MultiCursorMain", { bg = "#a6e3a1", fg = "#1e1e2e", bold = true })

-- ========================================================================== --
-- 3. WINBAR
-- ========================================================================== --

-- Per-split identifier winbar: makes it obvious which buffer/split you're in
-- when several are open side by side, with a modified indicator.
-- (The bottom statusline itself is now handled by lualine.nvim, see the
-- plugin spec section below.)
function _G.SimpleWinbar()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "[No Name]"
	end
	local modified = vim.bo.modified and " ●" or ""
	return "  " .. filename .. modified .. "  "
end
opt.winbar = "%{%v:lua.SimpleWinbar()%}"

-- ========================================================================== --
-- 4. GLOBAL KEYMAPS
-- ========================================================================== --
vim.keymap.set("n", "|", function()
	require("telescope.builtin").find_files({
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			local function select_vertical()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				vim.cmd("vsplit")
				vim.cmd("edit " .. vim.fn.fnameescape(selection.path or selection.filename))
			end

			map("i", "<CR>", select_vertical)
			map("n", "<CR>", select_vertical)
			return true
		end,
	})
end, { desc = "Find File and Split Vertically" })

vim.keymap.set("n", "_", function()
	require("telescope.builtin").find_files({
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			local function select_horizontal()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				vim.cmd("split")
				vim.cmd("edit " .. vim.fn.fnameescape(selection.path or selection.filename))
			end

			map("i", "<CR>", select_horizontal)
			map("n", "<CR>", select_horizontal)
			return true
		end,
	})
end, { desc = "Find File and Split Horizontally" })

vim.keymap.set("n", "<C-Left>", "<C-w>h", { desc = "Navigate to Left Window" })
vim.keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Navigate to Right Window" })
vim.keymap.set("n", "<C-Up>", "<C-w>k", { desc = "Navigate to Upper Window" })
vim.keymap.set("n", "<C-Down>", "<C-w>j", { desc = "Navigate to Lower Window" })
vim.keymap.set("n", "<C-S-z>", "<C-r>", { desc = "Redo Last Undo" })
vim.keymap.set("n", "<C-q>", "<cmd>mksession! .nvim_session | qa!<CR>", { desc = "Save Session and Quit Instantly" })
-- Render the current, saved Markdown file with Glow in a dedicated tab. This
-- complements the live editing view with a faithful final-read preview.
local function glow_preview()
	if vim.bo.filetype ~= "markdown" then
		vim.notify("Glow preview is only available for Markdown files", vim.log.levels.WARN)
		return
	end
	if vim.fn.executable("glow") == 0 then
		vim.notify("Glow is not available on PATH", vim.log.levels.ERROR)
		return
	end

	local filename = vim.api.nvim_buf_get_name(0)
	if filename == "" or vim.fn.filereadable(filename) == 0 then
		vim.notify("Save this note before opening its Glow preview", vim.log.levels.WARN)
		return
	end

	vim.cmd("tabnew")
	local width = math.max(vim.o.columns - 8, 40)
	vim.fn.termopen({ "glow", "--pager", "--style", "dark", "--width", tostring(width), filename })
	vim.bo.bufhidden = "wipe"
	vim.bo.filetype = "glow"
	vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = true, silent = true, desc = "Close Glow Preview" })
	vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("GlowPreview", glow_preview, { desc = "Preview the current Markdown file with Glow" })
vim.keymap.set("n", "<leader>mp", "<cmd>GlowPreview<CR>", { desc = "Preview Markdown with Glow" })
vim.keymap.set("n", "<leader>mt", "<cmd>RenderMarkdown toggle<CR>", { desc = "Open Terminal-Native Markdown toggle" })

-- Trouble can be closed from its own `q` mapping as well as from the leader
-- mappings below.  Always restore focus after *any* close, rather than trying
-- to infer panel state from its buffer. This avoids the occasional state where
-- the panel has disappeared but the current window is still a stale Trouble
-- buffer, so the next toggle only repairs focus instead of opening diagnostics.
local function is_editor_window(win)
	if not vim.api.nvim_win_is_valid(win) then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "trouble"
end

local function focus_code_window()
	if is_editor_window(vim.api.nvim_get_current_win()) then
		return
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if is_editor_window(win) then
			vim.api.nvim_set_current_win(win)
			return
		end
	end
end

local function toggle_trouble(opts)
	local trouble = require("trouble")
	if trouble.is_open(opts) then
		trouble.close(opts)
		-- The on_close hook covers q/Esc too; this schedule also makes the
		-- leader mapping safe with versions of Trouble that close asynchronously.
		vim.schedule(focus_code_window)
	else
		trouble.open(opts)
	end
end

vim.keymap.set("n", "<leader>df", function()
	toggle_trouble({ mode = "diagnostics", filter = { buf = 0 } })
end, { desc = "Diagnostics (Current File)" })

vim.keymap.set("n", "<leader>dw", function()
	toggle_trouble({ mode = "diagnostics" })
end, { desc = "Diagnostics (Workspace)" })

vim.keymap.set("t", "<C-Left>", [[<C-\><C-n><C-w>h]], { desc = "Navigate Left from Terminal" })
vim.keymap.set("t", "<C-Right>", [[<C-\><C-n><C-w>l]], { desc = "Navigate Right from Terminal" })
vim.keymap.set("t", "<C-Up>", [[<C-\><C-n><C-w>k]], { desc = "Navigate Upper from Terminal" })
vim.keymap.set("t", "<C-Down>", [[<C-\><C-n><C-w>j]], { desc = "Navigate Lower from Terminal" })
vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { desc = "Allow Ctrl+W window navigation inside terminal" })

-- VSCode-style indenting: select with Shift-V, tap Tab/Shift-Tab to indent
-- and stay in visual mode so you can keep pressing it.
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent Selection" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Outdent Selection" })

-- Quick window focus / layout reset
local function focus_editor()
	pcall(vim.cmd, "NvimTreeClose")

	-- Close Trouble via its own API (not the removed `:TroubleClose` command).
	-- Calling the real close() lets Trouble tear down its internal window
	-- state cleanly; if it's instead ripped out by `:only` below, Trouble is
	-- left thinking a dead window is still its panel, which is what caused
	-- the random "Invalid 'win': Expected Lua number" crash and dead
	-- diagnostics/LSP afterwards.
	local trouble_ok, trouble = pcall(require, "trouble")
	if trouble_ok then
		pcall(trouble.close)
	end

	pcall(vim.cmd, "DiffviewClose")

	local grugfar_ok, grugfar = pcall(require, "grug-far")
	if grugfar_ok then
		pcall(grugfar.close_instance, "search")
	end

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local cfg = vim.api.nvim_win_get_config(win)
		if cfg.relative ~= "" then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end

	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		local bt = vim.bo[buf].buftype
		local ft = vim.bo[buf].filetype

		if bt == "" and ft ~= "NvimTree" and ft ~= "trouble" and ft ~= "grug-far" and not ft:match("^Diffview") then
			vim.api.nvim_set_current_win(win)
			break
		end
	end

	vim.cmd("only")
end
vim.keymap.set("n", "<leader>wf", focus_editor, { desc = "Focus Editor" })

-- ========================================================================== --
-- 5. MARKDOWN / NOTES QUALITY-OF-LIFE
-- ========================================================================== --
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.conceallevel = 2 -- hides markup like Obsidian's live-preview
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.showbreak = "  "
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
		vim.opt_local.foldmethod = "expr"
		vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.opt_local.foldlevel = 99 -- headings foldable, but start fully open
	end,
})

-- ========================================================================== --
-- 6. LAZY.NVIM BOOTSTRAP
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- ========================================================================== --
-- 7. LSP ON_ATTACH
-- ========================================================================== --
local function lsp_on_attach(client, bufnr)
	local opts = { buffer = bufnr }
	local ts_builtin = require("telescope.builtin")

	vim.keymap.set("n", "gd", ts_builtin.lsp_definitions, opts)
	vim.keymap.set("n", "gv", function()
		ts_builtin.lsp_definitions({ jump_type = "vsplit" })
	end, { buffer = bufnr, desc = "LSP Definition (Vertical Split)" })

	vim.keymap.set("n", "gh", function()
		ts_builtin.lsp_definitions({ jump_type = "split" })
	end, { buffer = bufnr, desc = "LSP Definition (Horizontal Split)" })
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	local gs = require("gitsigns")

	vim.keymap.set("n", "<leader>gh", function()
		gs.setqflist("all")
		vim.cmd("copen")
	end, { desc = "Git Changed Lines in Current File" })

	vim.keymap.set("n", "<leader>gp", function()
		gs.preview_hunk()
	end, { desc = "Preview Current Git Hunk" })

	vim.keymap.set("n", "<leader>gd", function()
		gs.diffthis()
	end, { desc = "Diff Current File Against Index" })

	vim.keymap.set("n", "<leader>gD", function()
		gs.diffthis("~")
	end, { desc = "Diff Current File Against HEAD" })

	vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous Diagnostic" })
	vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next Diagnostic" })
	vim.keymap.set("n", "<leader>ld", vim.diagnostic.setloclist, { buffer = bufnr, desc = "Buffer Diagnostics List" })
	vim.keymap.set("n", "gr", function()
		ts_builtin.lsp_references({ include_declaration = false })
	end, opts)
	vim.keymap.set("n", "gi", ts_builtin.lsp_implementations, opts)
	vim.keymap.set("n", "gt", ts_builtin.lsp_type_definitions, opts)

	vim.keymap.set("n", "K", function()
		local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
		if #diagnostics > 0 then
			vim.diagnostic.open_float(nil, {
				focusable = true,
				border = "rounded",
				close_events = { "CursorMoved" },
				source = "always",
			})
		else
			vim.lsp.buf.hover()
		end
	end, opts)

	vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
	vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
	vim.keymap.set("n", "<leader>ls", ts_builtin.lsp_document_symbols, { buffer = bufnr, desc = "Document Symbols" })
	vim.keymap.set("n", "<leader>lw", ts_builtin.lsp_workspace_symbols, { desc = "Workspace Symbols" })
	vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { buffer = bufnr, desc = "LSP Code Actions" })
	vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename Symbol" })
	vim.keymap.set("n", "<leader>lf", function()
		require("conform").format({ async = false })
	end, { buffer = bufnr })
	vim.keymap.set("n", "<leader>li", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
	end, { buffer = bufnr, desc = "Toggle Inlay Hints" })

	-- Rust-only: rust_analyzer is the one server that reliably gets into a
	-- stuck/panicked state worth force-restarting. Restrict this to actual
	-- rust file buffers (buftype == "" means a normal, on-disk/editable
	-- buffer, not a terminal/help/nofile buffer) so it's never fired
	-- somewhere it can't do anything useful.
	vim.keymap.set("n", "<leader>lR", function()
		if vim.bo[bufnr].buftype ~= "" then
			vim.notify("LSP restart is only available for normal file buffers", vim.log.levels.WARN)
			return
		end

		local clients = vim.lsp.get_clients({ bufnr = bufnr })
		if #clients == 0 then
			vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
			return
		end

		local names = {}
		for _, client in ipairs(clients) do
			if client.name ~= "copilot" and client.name ~= "null-ls" then
				table.insert(names, client.name)
			end
		end

		if #names == 0 then
			vim.notify("No restartable LSP client attached to this buffer", vim.log.levels.WARN)
			return
		end

		vim.diagnostic.reset(nil, bufnr)
		vim.cmd("LspRestart " .. table.concat(names, " "))
		vim.notify("Restarted LSP: " .. table.concat(names, ", "), vim.log.levels.INFO)
	end, { buffer = bufnr, desc = "Restart LSP for Current File" })
end

-- ========================================================================== --
-- 8. PLUGIN SPECS
-- ========================================================================== --
vim.cmd.colorscheme("kuro_nezumi")

require("lazy").setup({
	{ "j-hui/fidget.nvim", event = "VeryLazy", opts = {} },

	{
		"romgrk/barbar.nvim",
		event = "VeryLazy", -- perf: don't block startup for the bufferline
		dependencies = { "lewis6991/gitsigns.nvim", "nvim-tree/nvim-web-devicons" },
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {},
		version = "^1.0.0",
	},

	-- Bottom statusline: filename, line count, error/warning counts. Replaces
	-- the old hand-rolled statusline with lualine, kept to the same 3 pieces
	-- of information (nothing else).
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					globalstatus = true, -- one global statusline, matches laststatus = 3
					component_separators = { left = "│", right = "│" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = { "filename" },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {
						{
							function()
								return "Lines: " .. vim.fn.line("$")
							end,
						},
					},
					lualine_y = {
						{
							-- Built directly on vim.diagnostic.count() (same call your
							-- old custom statusline used) instead of lualine's built-in
							-- "diagnostics" component, so counts show reliably regardless
							-- of which diagnostic source lualine expects.
							function()
								local ok, counts = pcall(vim.diagnostic.count, 0)
								if not ok or not counts then
									return ""
								end
								local errors = counts[vim.diagnostic.severity.ERROR] or 0
								local warnings = counts[vim.diagnostic.severity.WARN] or 0
								local parts = {}
								if errors > 0 then
									table.insert(parts, "E:" .. errors)
								end
								if warnings > 0 then
									table.insert(parts, "W:" .. warnings)
								end
								return table.concat(parts, " ")
							end,
							color = function()
								local ok, counts = pcall(vim.diagnostic.count, 0)
								if not ok or not counts then
									return
								end
								if (counts[vim.diagnostic.severity.ERROR] or 0) > 0 then
									return { fg = "#f38ba8", bold = true }
								elseif (counts[vim.diagnostic.severity.WARN] or 0) > 0 then
									return { fg = "#fab387", bold = true }
								end
							end,
						},
					},
					lualine_z = {},
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
			})
		end,
	},

	{ "windwp/nvim-autopairs", event = "InsertEnter", config = true },

	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "markdown" },
		config = function()
			require("render-markdown").setup({
				completions = { lsp = { enabled = true } },
				-- Keep syntax visible while actively editing a line, then render it
				-- as a clean live preview when the cursor moves away (Obsidian-like).
				anti_conceal = {
					enabled = true,
					above = 1,
					below = 1,
					ignore = { code_background = true, indent = true, link = true, sign = true, virtual_lines = true },
				},
				heading = { position = "inline", width = "block" },
				code = { style = "full", position = "left", width = "block", left_pad = 2, right_pad = 4 },
				pipe_table = { preset = "round" },
				quote = { repeat_linebreak = true },
				checkbox = {
					custom = {
						todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
						important = { raw = "[!]", rendered = " ", highlight = "RenderMarkdownWarn" },
						question = { raw = "[?]", rendered = " ", highlight = "RenderMarkdownInfo" },
						forward = { raw = "[>]", rendered = " ", highlight = "RenderMarkdownHint" },
					},
				},
			})
		end,
	},

	-- Obsidian-style notes: wiki-links, backlinks, tags, daily notes,
	-- checkboxes - layered on top of render-markdown.nvim.
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		ft = "markdown",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			workspaces = {
				{ name = "notes", path = "~/notes" },
			},
			completion = {
				-- obsidian.nvim's bundled completion source is for nvim-cmp only.
				-- Blink still provides LSP/path/buffer completion; note discovery is
				-- handled by the dedicated picker commands below.
				nvim_cmp = false,
				min_chars = 2,
			},
			ui = { enable = false }, -- render-markdown.nvim already renders the UI
			picker = { name = "telescope.nvim" },
			templates = { folder = "templates" },
			attachments = { img_folder = "assets" },
			daily_notes = {
				folder = "daily",
				date_format = "%Y-%m-%d",
			},
			checkbox = {
				order = { " ", "x" },
			},
		},
		config = function(_, opts)
			require("obsidian").setup(opts)
			vim.keymap.set("n", "<leader>nn", "<cmd>ObsidianNew<CR>", { desc = "New Note" })
			vim.keymap.set("n", "<leader>nd", "<cmd>ObsidianToday<CR>", { desc = "Today's Daily Note" })
			vim.keymap.set("n", "<leader>nf", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick Switch Note" })
			vim.keymap.set("n", "<leader>ns", "<cmd>ObsidianSearch<CR>", { desc = "Search Notes" })
			vim.keymap.set("n", "<leader>nb", "<cmd>ObsidianBacklinks<CR>", { desc = "Show Backlinks" })
			vim.keymap.set("n", "<leader>nt", "<cmd>ObsidianTags<CR>", { desc = "Browse Tags" })
			vim.keymap.set("n", "<leader>nc", "<cmd>ObsidianToggleCheckbox<CR>", { desc = "Toggle Checkbox" })
			vim.keymap.set("n", "<leader>nl", "<cmd>ObsidianLinks<CR>", { desc = "Links in Note" })
			vim.keymap.set("n", "<leader>no", "<cmd>ObsidianTOC<CR>", { desc = "Note Outline" })
			vim.keymap.set("n", "<leader>np", "<cmd>ObsidianPasteImg<CR>", { desc = "Paste Image into Note" })
			vim.keymap.set("n", "<leader>ny", "<cmd>ObsidianYesterday<CR>", { desc = "Yesterday's Daily Note" })
			vim.keymap.set("n", "<leader>nr", "<cmd>ObsidianTomorrow<CR>", { desc = "Tomorrow's Daily Note" })
		end,
	},

	{ "nvim-treesitter/nvim-treesitter-textobjects" },

	-- Multi-cursor editing on word/symbol occurrences.
	--   <C-d> on a word          -> select it, <C-d> again to add the next
	--                                occurrence (VSCode-style)
	--   c / C  (in multicursor mode) -> delete every selection and drop
	--                                    straight into insert, so whatever
	--                                    you type next replaces all of them
	--   i / a                    -> just enter insert mode at each
	--                                selection without deleting it
	--   P      (in multicursor mode) -> paste the current register over
	--                                    every selection
	--   Esc                      -> leave multicursor mode
	{
		"smoka7/multicursors.nvim",
		event = "VeryLazy",
		dependencies = { "nvimtools/hydra.nvim" },
		opts = {
			hint_config = false, -- no more floating hint/options window popping up
			normal_keys = {
				C = {
					method = function()
						require("multicursors.utils").call_on_selections(function(selection)
							vim.api.nvim_buf_set_text(
								0,
								selection.row,
								selection.col,
								selection.end_row,
								selection.end_col,
								{}
							)
						end)
						vim.cmd("startinsert")
					end,
					opts = { desc = "Clear all selections and start typing" },
				},
				P = {
					method = function()
						local reg = vim.fn.getreg('"')
						local lines = vim.split(reg, "\n")
						require("multicursors.utils").call_on_selections(function(selection)
							vim.api.nvim_buf_set_text(
								0,
								selection.row,
								selection.col,
								selection.end_row,
								selection.end_col,
								lines
							)
						end)
					end,
					opts = { desc = "Paste register over all selections" },
				},
			},
		},
		config = function(_, opts)
			require("multicursors").setup(opts)
			vim.keymap.set({ "n", "v" }, "<C-d>", function()
				vim.cmd("MCstart")
			end, { silent = true, desc = "Multi-cursor: select word under cursor / next match" })
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>ff", desc = "Search Files by Name" },
			{ "<leader>fg", desc = "Project Search" },
			{ "<leader>fb", desc = "Search Text in Current File" },
		},
		config = function()
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search Files by Name" })
			vim.keymap.set("n", "<leader>fg", function()
				require("grug-far").toggle_instance({
					instanceName = "search",
					prefills = { flags = "--fixed-strings" },
				})
			end, { desc = "Project Search" })
			vim.keymap.set(
				"n",
				"<leader>fb",
				builtin.current_buffer_fuzzy_find,
				{ desc = "Search Text in Current File" }
			)
		end,
	},

	{
		"MagicDuck/grug-far.nvim",
		cmd = "GrugFar",
		opts = {
			windowCreationCommand = "vertical botright 50split",
			keymaps = { close = { n = "q" } },
		},
	},

	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {
			auto_close = false,
			focus = true,
			win = { position = "right", size = 60 },
			on_close = function()
				-- This fires for Trouble's own q mapping too, not only our
				-- <leader>d toggles. Defer until Neovim has selected its next
				-- window, then make sure it is a real editor buffer.
				vim.schedule(focus_code_window)
			end,
			-- NOTE: previously `preview = { type = "split", relative = "win",
			-- position = "bottom", size = 0.40 }`.
			-- `relative = "win"` requires Trouble to also pass a concrete
			-- numeric window handle to Neovim's window API, which it never
			-- does for this field. That mismatch is exactly what threw
			-- "Invalid 'win': Expected Lua number" (window.lua:178), and once
			-- it errored mid-render it left the Trouble panel + diagnostics
			-- in a broken half-open state until a full restart. The default
			-- preview (type = "main", drawn in the current editor window) is
			-- safe and doesn't need this option at all.
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				watch_gitdir = { interval = 1000, follow_files = true },
				attach_to_untracked = true,
				current_line_blame = false,
			})
		end,
	},

	{
		-- Enriched git workflow:
		--   <leader>gf  -> current file's history across commits, two-pane
		--                  (LEFT = your working copy, editable; RIGHT = the
		--                  commit selected in the log panel, with live preview
		--                  as you move up/down the log)
		--   <leader>gl  -> select lines with Shift-V then press this to see
		--                  ONLY those lines' history across commits
		--                  (diffview drives `git log -L` under the hood when
		--                  it is invoked from a visual selection)
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		keys = {
			{ "<leader>gf", desc = "File History (Two-Pane Diff)" },
			{ "<leader>gl", mode = "v", desc = "Line History Across Commits" },
			{ "<leader>gcc", desc = "Browse Commits & View Changed Files" },
			{ "<leader>gdc", desc = "Close Diff Workspace" },
			{ "<leader>gco", desc = "Git checkout changes" },
		},
		config = function()
			require("diffview").setup({
				enhanced_diff_hl = true,
				use_icons = false,
				view = {
					default = { layout = "diff2_horizontal" },
					file_history = { layout = "diff2_horizontal" }, -- left=current/editable, right=selected commit
					merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
				},
				file_history_panel = { win_config = { position = "bottom", height = 16 } },
				hooks = {
					diff_buf_win_enter = function(bufnr, winid, ctx)
						vim.wo[winid].foldenable = false
						vim.wo[winid].foldmethod = "manual"
						if ctx and ctx.view and ctx.view.type == "file_history" and vim.bo[bufnr].modifiable then
							vim.api.nvim_win_call(winid, function()
								vim.cmd("wincmd H")
							end)
						end
					end,
				},
				keymaps = {
					view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } } },
					file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } } },
					file_history_panel = {
						{ "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } },
					},
				},
			})

			local function open_commit_picker_diff()
				local has_telescope, telescope_builtin = pcall(require, "telescope.builtin")
				if not has_telescope then
					return
				end
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")

				telescope_builtin.git_commits({
					prompt_title = "🗂️ Select Commit to View Changed Files",
					attach_mappings = function(prompt_bufnr, map)
						actions.select_default:replace(function()
							actions.close(prompt_bufnr)
							local selection = action_state.get_selected_entry()
							if selection then
								vim.cmd("NvimTreeClose")
								vim.cmd("DiffviewOpen " .. selection.value .. "~1.." .. selection.value)
							end
						end)
						return true
					end,
				})
			end

			local function git_checkout()
				local checkout_out = vim.fn.system("git checkout .")
				if vim.v.shell_error ~= 0 then
					vim.notify("Git Checkout Failed:\n" .. checkout_out, vim.log.levels.ERROR)
				end
			end

			-- current file across commits, two-pane, left editable / right preview
			vim.keymap.set("n", "<leader>gf", function()
				pcall(vim.cmd, "NvimTreeClose")
				vim.cmd("DiffviewFileHistory % --base=LOCAL")
			end, { desc = "File History (Two-Pane Diff)" })

			-- visual-select lines, then see only those lines' history
			vim.keymap.set("v", "<leader>gl", "<Esc><Cmd>'<,'>DiffviewFileHistory<CR>", {
				desc = "Line History Across Commits",
			})

			vim.keymap.set(
				"n",
				"<leader>gcc",
				open_commit_picker_diff,
				{ desc = "Browse Commits & View Changed Files" }
			)
			vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Diff Workspace" })
			vim.keymap.set("n", "<leader>gco", git_checkout, { desc = "Git checkout changes" })
		end,
	},

	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeClose" },
		keys = { { "<leader>e", desc = "Toggle File Tree" } },
		config = function()
			require("nvim-tree").setup({
				renderer = {
					-- A clean text tree: hierarchy and highlights communicate state
					-- without depending on icon fonts.
					group_empty = true,
					root_folder_label = function(path)
						return "  " .. vim.fn.fnamemodify(path, ":~")
					end,
					indent_width = 2,
					highlight_git = "name",
					highlight_opened_files = "all",
					highlight_modified = "name",
					indent_markers = {
						enable = true,
						inline_arrows = true,
						icons = { corner = "└", edge = "│", item = "│", bottom = "─", none = " " },
					},
					icons = { show = { file = false, folder = false, folder_arrow = false, git = false } },
				},
				actions = {
					open_file = {
						quit_on_open = false,
						resize_window = true,
						-- Opening a file returns directly to the previous editor; use
						-- v/s for deliberate vertical/horizontal splits.
						window_picker = { enable = false },
					},
				},
				-- Fix (paired with the cwd jump at the top of this file): even
				-- with the correct cwd on startup, nvim-tree can otherwise drift
				-- back to whatever the *shell's* cwd was as you move between
				-- buffers in different subdirectories. These two options keep
				-- the tree's root following the actual project you're editing
				-- (git-root aware) instead of silently pinning to A.
				update_focused_file = {
					enable = true,
					update_root = { enable = true, ignore_list = {} },
				},
				respect_buf_cwd = true,
				sync_root_with_cwd = true,
				view = {
					width = 36,
					preserve_window_proportions = true,
					centralize_selection = true,
					cursorline = true,
				},
				filters = { dotfiles = false, git_ignored = false },
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")
					local function map(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs, {
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
							desc = desc,
						})
					end

					api.config.mappings.default_on_attach(bufnr)
					map("l", api.node.open.edit, "Open")
					map("h", api.node.navigate.parent_close, "Close Folder")
					map("v", api.node.open.vertical, "Open Vertical Split")
					map("s", api.node.open.horizontal, "Open Horizontal Split")
					map("a", api.fs.create, "Create")
					map("r", api.fs.rename, "Rename")
					map("d", api.fs.remove, "Delete")
					-- Move workflow: m marks the file/folder for moving (without
					-- changing it yet); navigate to a destination folder and press p.
					map("m", api.fs.cut, "Move: Select File or Folder")
					map("p", api.fs.paste, "Move: Paste into Destination")
					map("f", api.live_filter.start, "Filter")
					map("H", api.tree.toggle_hidden_filter, "Toggle Hidden Files")
					map("R", api.tree.reload, "Refresh")
				end,
			})

			local hl = vim.api.nvim_set_hl
			hl(0, "NvimTreeFolderName", { fg = "#83a598", bold = true })
			hl(0, "NvimTreeOpenedFolderName", { fg = "#fabd2f", bold = true })
			hl(0, "NvimTreeRootFolder", { fg = "#d79921", bold = true })
			hl(0, "NvimTreeOpenedFile", { fg = "#d3869b", bold = true, underline = true })
			hl(0, "NvimTreeIndentMarker", { fg = "#504945" })
			vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true, desc = "Toggle File Tree" })
		end,
	},

	-- Lean which-key guide: only top-level groups + the handful of
	-- mappings that aren't self-explanatory from their buffer-local `desc`.
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({
				preset = "modern",
				win = { border = "rounded" },
				icons = { mappings = false }, -- plain text, no nerd-font dependency, lean look
			})
			wk.add({
				{ "<leader>w", group = "Window" },
				{ "<leader>m", group = "Markdown" },
				{ "<leader>d", group = "Diagnostics" },
				{ "<leader>f", group = "Find" },
				{ "<leader>g", group = "Git" },
				{ "<leader>l", group = "LSP" },
				{ "<leader>n", group = "Notes" },
				{ "<leader>p", group = "Project" },
				{ "<leader>wq", "<C-w>c", desc = "Close Split" },
				{ "<leader>wo", "<C-w>o", desc = "Only This Window" },
				{ "<leader>w=", "<C-w>=", desc = "Equalize Splits" },
				{ "<leader>wx", "<cmd>vsplit<CR>", desc = "Vertical Split" },
				{ "<leader>ws", "<cmd>split<CR>", desc = "Horizontal Split" },
				{ "<leader>wn", "<cmd>BufferNext<CR>", desc = "Next Buffer" },
				{ "<leader>wp", "<cmd>BufferPrevious<CR>", desc = "Previous Buffer" },
				{ "<leader>ww", "<cmd>BufferPick<CR>", desc = "Pick Buffer" },
				{ "<leader>wl", "<cmd>BufferPin<CR>", desc = "Pin Buffer" },
				{ "<leader>wc", "<cmd>wq!<CR>", desc = "Write and Quit" },
				{ "<leader>gh", desc = "File History Log (Split)" },
				{ "<leader>gdf", desc = "Current File Diff Right Split" },
				{ "<leader>gdl", mode = "v", desc = "Selected Lines Git History" },
			})
		end,
	},

	{ "neovim/nvim-lspconfig" },

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		opts = {
			formatters_by_ft = {
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				javascript = { "prettierd" },
				javascriptreact = { "prettierd" },
				rust = { "rustfmt", lsp_format = "fallback" },
				lua = { "stylua" },
				c = { "clang-format" },
				sh = { "shfmt" },
				markdown = { "prettierd" },
				-- goimports removes unused imports + adds missing ones, then
				-- gofumpt applies a stricter superset of gofmt formatting.
				-- Order matters: imports are fixed first, then formatted.
				go = { "goimports", "gofumpt" },
			},
			format_on_save = function(bufnr)
				-- sqls' formatter destroys PostgreSQL procedural blocks such as
				-- DO $$ ... $$, so keep SQL completion/linting but never rewrite
				-- SQL automatically. Other filetypes retain their LSP fallback.
				if vim.bo[bufnr].filetype == "sql" then
					return nil
				end
				return {
					timeout_ms = 2000,
					lsp_format = "fallback",
				}
			end,
		},
	},

	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		event = "VeryLazy",
		config = function()
			require("mason").setup()
		end,
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = "VeryLazy",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			-- These are CLI tools rather than LSP servers, so mason-lspconfig
			-- does not install them. Keep the formatter/linter setup reproducible.
			ensure_installed = { "goimports", "gofumpt", "golangci-lint", "sqlfluff" },
			run_on_start = true,
		},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig", "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = {
					"rust_analyzer",
					"gopls",
					"sqls",
					"lua_ls",
					"ts_ls",
					"bashls",
					"dockerls",
					"marksman",
				},
				-- Mason otherwise auto-enables *every* server installed on this
				-- machine (including unrelated ones such as harper_ls and pyright).
				-- Configure and enable only the servers below, so a stray server
				-- cannot duplicate diagnostics or interfere with completion.
				automatic_enable = false,
			})

			-- sqls can work without a live connection, but schema-aware
			-- PostgreSQL completion needs one. Reuse DATABASE_URL when present
			-- without committing credentials to this dotfile.
			local sqls_settings = {}
			if vim.env.DATABASE_URL and vim.env.DATABASE_URL ~= "" then
				sqls_settings = {
					sqls = {
						connections = {
							{ alias = "postgres", driver = "postgresql", dataSourceName = vim.env.DATABASE_URL },
						},
					},
				}
			end

			local servers = {
				lua_ls = { settings = { Lua = { diagnostics = { globals = { "vim" } } } } },
				ts_ls = {
					settings = {
						typescript = {
							suggest = { completeFunctionCalls = true },
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
							},
						},
					},
				},
				-- You develop on macOS but target Linux, and libc / other
				-- unix-only crates don't resolve correctly if rust-analyzer
				-- assumes the host (mac) target. Pinning the cargo target to a
				-- Linux triple makes it analyze the project as if it were
				-- being built on Linux.
				rust_analyzer = {
					settings = {
						["rust-analyzer"] = {
							cargo = {
								-- target = "x86_64-unknown-linux-gnu", -- << change if you target a different linux arch
								allFeatures = true,
							},
							check = { command = "clippy" },
							checkOnSave = true,
						},
					},
				},
				-- Mirrors the rust_analyzer treatment above: richer analyses,
				-- inlay hints, and gofumpt-aware formatting so gopls agrees
				-- with the conform.nvim formatters configured for Go.
				gopls = {
					root_markers = { "go.work", "go.mod", ".git" },
					settings = {
						gopls = {
							gofumpt = true,
							usePlaceholders = true,
							completeUnimported = true,
							completeFunctionCalls = true,
							expandWorkspaceToModule = true,
							symbolScope = "all",
							staticcheck = true,
							semanticTokens = true,
							-- Parsing/type errors still appear immediately; this shortens the
							-- pause before the more expensive package diagnostics appear.
							diagnosticsDelay = "300ms",
							directoryFilters = { "-.git", "-**/node_modules", "-**/vendor" },
							analyses = {
								unusedparams = true,
								unusedwrite = true,
								shadow = true,
							},
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
						},
					},
				},
				sqls = {
					filetypes = { "sql" },
					root_markers = { ".sqllsrc.json", "go.work", "go.mod", ".git" },
					settings = sqls_settings,
				},
				bashls = {},
				dockerls = {},
				marksman = {},
			}

			for server, config in pairs(servers) do
				config.capabilities = capabilities
				vim.lsp.config(server, config)
				vim.lsp.enable(server)
			end
		end,
	},

	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				go = { "golangcilint" },
				sql = { "sqlfluff" },
			}

			-- golangci-lint uses exit code 7 when package loading/typechecking
			-- fails (common briefly while editing). gopls already publishes the
			-- useful compiler diagnostic; keep parsing any linter JSON without
			-- showing a redundant command-failed notification on every save.
			lint.linters.golangcilint.ignore_exitcode = true

			-- Make SQLFluff parse stdin as PostgreSQL even when a project does
			-- not yet have its own .sqlfluff configuration file.
			lint.linters.sqlfluff.args = { "lint", "--dialect=postgres", "--format=json", "-" }

			vim.api.nvim_create_autocmd("BufWritePost", {
				group = vim.api.nvim_create_augroup("LintOnSave", { clear = true }),
				callback = function()
					if vim.bo.buftype == "" then
						lint.try_lint()
					end
				end,
			})
		end,
	},

	{
		"saghen/blink.cmp",
		version = "*",
		event = "InsertEnter", -- perf: only load once you actually start typing
		dependencies = { "rafamadriz/friendly-snippets", "onsails/lspkind.nvim" },
		opts = {
			keymap = {
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			},
			appearance = {
				use_nvim_cmp_as_default = false,
				nerd_font_variant = "mono",
			},
			completion = {
				accept = { auto_brackets = { enabled = true } },
				documentation = { auto_show = true, auto_show_delay_ms = 200 },
				menu = {
					border = "rounded",
					draw = {
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "kind" },
						},
					},
				},
				list = { selection = { preselect = true, auto_insert = false } },
			},
			signature = { enabled = true },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
})

-- ========================================================================== --
-- 9. AUTOCOMMANDS
-- ========================================================================== --

vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#545464", bg = "NONE", italic = true })

-- LSP logs are invaluable while debugging, but an unbounded log had grown to
-- several gigabytes here. Retain the latest diagnostics only, without doing a
-- costly full-file read when Neovim exits.
vim.api.nvim_create_autocmd("VimLeave", {
	group = vim.api.nvim_create_augroup("KeepRecentLspLog", { clear = true }),
	callback = function()
		local log_path = vim.lsp.log.get_filename()
		local recent = vim.fn.systemlist({ "tail", "-n", "100", log_path })
		if vim.v.shell_error == 0 then
			vim.fn.writefile(recent, log_path)
		end
	end,
})

vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		if vim.bo.buftype ~= "" or vim.bo.filetype == "help" then
			return
		end
		for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
			if vim.api.nvim_win_get_config(winid).zindex then
				return
			end
		end

		local bufnr = vim.api.nvim_get_current_buf()
		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
		if #vim.diagnostic.get(bufnr, { lnum = lnum }) > 0 then
			vim.diagnostic.open_float(bufnr, {
				scope = "cursor",
				border = "rounded",
				focusable = false,
				open_fold = true,
				close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
				source = "always",
				severity_sort = true,
			})
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			lsp_on_attach(client, args.buf)
		end
	end,
})

-- This is the main fix for "weird errors that build up over hours".
-- The most common cause is orphaned LSP clients / stale diagnostics left
-- behind on buffers that were closed and reopened. Clearing diagnostics on
-- detach, and stopping any client with no attached buffers left, reproduces
-- what a full nvim restart used to do for you automatically.
vim.api.nvim_create_autocmd("LspDetach", {
	group = vim.api.nvim_create_augroup("UserLspDetach", { clear = true }),
	callback = function(args)
		vim.diagnostic.reset(nil, args.buf)
	end,
})

vim.api.nvim_create_autocmd("BufDelete", {
	group = vim.api.nvim_create_augroup("UserLspCleanup", { clear = true }),
	callback = function()
		vim.defer_fn(function()
			for _, client in ipairs(vim.lsp.get_clients()) do
				if vim.tbl_isempty(client.attached_buffers or {}) then
					client:stop()
				end
			end
		end, 200)
	end,
})

vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
	pattern = "term://*",
	callback = function()
		vim.cmd("startinsert")
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if vim.fn.argc() == 0 and vim.fn.filereadable(".nvim_session") == 1 then
			vim.cmd("source .nvim_session")
		end
	end,
})
local original_notify = vim.notify
vim.notify = function(msg, log_level, opts)
	if msg and msg:match("rust_analyzer: %-32603: request handler panicked") then
		return
	end
	original_notify(msg, log_level, opts)
end

-- Closes every real buffer. Buffers backed by a file that no longer exists
-- on disk (renamed/deleted outside nvim) are force-closed automatically,
-- since there's nothing left to save. Buffers with unsaved changes to a
-- file that DOES still exist are left alone (nvim will just refuse the
-- delete rather than silently losing your edits).
local function close_all_tabs()
	local skipped = 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
			local name = vim.api.nvim_buf_get_name(buf)
			local file_missing = name ~= "" and vim.fn.filereadable(name) == 0

			local ok = pcall(vim.api.nvim_buf_delete, buf, { force = file_missing })
			if not ok then
				skipped = skipped + 1
			end
		end
	end
	if skipped > 0 then
		vim.notify(skipped .. " buffer(s) kept open (unsaved changes)", vim.log.levels.WARN)
	end
end
vim.keymap.set("n", "<leader>wA", close_all_tabs, { desc = "Close All Tabs (Auto-Clean Missing Files)" })

-- ========================================================================== --
-- 10. PROJECT MANAGEMENT
-- ========================================================================== --
-- <leader>ps  -> save the current working directory as a named project
-- <leader>pd  -> pick a saved project and delete it
-- <leader>pl  -> pick a saved project and jump (cd) to it, refreshing nvim-tree
--
-- Projects are stored as { name = { path = "..." }, ... } in a JSON file at
-- ~/.config/nvim/projects.json (stdpath("config") so it follows your
-- normal nvim config location, not hardcoded to $HOME).

local projects_file = vim.fn.stdpath("config") .. "/projects.json"

local function projects_load()
	if vim.fn.filereadable(projects_file) == 0 then
		return {}
	end
	local raw = table.concat(vim.fn.readfile(projects_file), "\n")
	if raw == "" then
		return {}
	end
	local ok, decoded = pcall(vim.fn.json_decode, raw)
	if not ok or type(decoded) ~= "table" then
		vim.notify("projects.json is corrupt, starting fresh", vim.log.levels.WARN)
		return {}
	end
	return decoded
end

local function projects_save(projects)
	local ok, encoded = pcall(vim.fn.json_encode, projects)
	if not ok then
		vim.notify("Failed to encode projects.json", vim.log.levels.ERROR)
		return
	end
	vim.fn.writefile({ encoded }, projects_file)
end

local function project_save()
	local default_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	vim.ui.input({ prompt = "Save project as: ", default = default_name }, function(name)
		if not name or name == "" then
			return
		end
		local projects = projects_load()
		projects[name] = { path = vim.fn.getcwd() }
		projects_save(projects)
		vim.notify("Saved project '" .. name .. "' -> " .. vim.fn.getcwd(), vim.log.levels.INFO)
	end)
end

local function project_delete()
	local projects = projects_load()
	local names = vim.tbl_keys(projects)
	if #names == 0 then
		vim.notify("No saved projects", vim.log.levels.WARN)
		return
	end
	table.sort(names)
	vim.ui.select(names, {
		prompt = "Delete project:",
		format_item = function(name)
			return name .. "  (" .. projects[name].path .. ")"
		end,
	}, function(choice)
		if not choice then
			return
		end
		projects[choice] = nil
		projects_save(projects)
		vim.notify("Deleted project '" .. choice .. "'", vim.log.levels.INFO)
	end)
end

local function project_list()
	local projects = projects_load()
	local names = vim.tbl_keys(projects)
	if #names == 0 then
		vim.notify("No saved projects", vim.log.levels.WARN)
		return
	end
	table.sort(names)
	vim.ui.select(names, {
		prompt = "Open project:",
		format_item = function(name)
			return name .. "  (" .. projects[name].path .. ")"
		end,
	}, function(choice)
		if not choice then
			return
		end
		local path = projects[choice].path
		if vim.fn.isdirectory(path) == 0 then
			vim.notify("Project path no longer exists: " .. path, vim.log.levels.ERROR)
			return
		end
		vim.cmd("cd " .. vim.fn.fnameescape(path))
		-- Keep nvim-tree's root in sync if it's already loaded/open.
		pcall(vim.cmd, "NvimTreeChangeRoot " .. vim.fn.fnameescape(path))
		vim.notify("Switched to project '" .. choice .. "' -> " .. path, vim.log.levels.INFO)
	end)
end

vim.keymap.set("n", "<leader>ps", project_save, { desc = "Save Project" })
vim.keymap.set("n", "<leader>pd", project_delete, { desc = "Delete Project" })
vim.keymap.set("n", "<leader>pl", project_list, { desc = "List Projects" })
vim.keymap.set("n", "<leader>gdf", function()
	pcall(vim.cmd, "NvimTreeClose")
	vim.cmd("DiffviewOpen -- %")
end, { desc = "Current File Diff Right Split" })

vim.keymap.set("v", "<leader>gdl", "<Esc><Cmd>'<,'>DiffviewFileHistory %<CR>", {
	desc = "Selected Lines Git History",
})
