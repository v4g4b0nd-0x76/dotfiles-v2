-- ========================================================================== --
-- [[                        STRUCTURED NVIM CONFIG                        ]] --
-- ==========================================================================--
-- Sections:
--   1. Base options & performance
--   2. Highlight groups (diagnostics, statusline, winbar, splits)
--   3. Statusline (bottom, global) & Winbar (per-split identifier)
--   4. Global keymaps (navigation, sessions, diagnostics, indenting, git)
--   5. Markdown / notes quality-of-life
--   6. Lazy.nvim bootstrap
--   7. LSP on_attach
--   8. Plugin specs
--   9. Autocommands (LSP health/cleanup, terminal, sessions, focus helper)
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
opt.laststatus = 3 -- ONE global statusline at the very bottom (point 1)
opt.fillchars = { vert = "│", eob = " " } -- cleaner vertical split separators (point 6)

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

-- Statusline (point 1)
vim.api.nvim_set_hl(0, "StatusLineFile", { fg = "#1e1e2e", bg = "#a6adc8", bold = true })
vim.api.nvim_set_hl(0, "StatusLineSep", { fg = "#6c7086" })
vim.api.nvim_set_hl(0, "StatusLineError", { fg = "#f38ba8", bold = true })
vim.api.nvim_set_hl(0, "StatusLineWarn", { fg = "#fab387", bold = true })

-- Winbar (point 6) - Neovim uses "WinBar" for the focused split and
-- "WinBarNC" for every other split automatically, so styling these two
-- groups is enough to make each split visually distinct.
vim.api.nvim_set_hl(0, "WinBar", { fg = "#1e1e2e", bg = "#a6adc8", bold = true })
vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#6c7086", bg = "NONE", italic = true })
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#a6adc8", bold = true })

-- ========================================================================== --
-- 3. STATUSLINE & WINBAR
-- ========================================================================== --

-- Bottom statusline: filename, total lines, error/warning counts. Nothing else. (point 1)
function _G.SimpleStatusline()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "[No Name]"
	end
	local total_lines = vim.fn.line("$")

	local errors, warnings = 0, 0
	local ok, counts = pcall(vim.diagnostic.count, 0)
	if ok and counts then
		errors = counts[vim.diagnostic.severity.ERROR] or 0
		warnings = counts[vim.diagnostic.severity.WARN] or 0
	end

	local parts = {
		"%#StatusLineFile# " .. filename .. " %#StatusLine#",
		"%#StatusLineSep# │ %#StatusLine#Lines: " .. total_lines .. " ",
	}
	if errors > 0 then
		table.insert(parts, "%#StatusLineSep#│ %#StatusLineError#E:" .. errors .. " %#StatusLine#")
	end
	if warnings > 0 then
		table.insert(parts, "%#StatusLineSep#│ %#StatusLineWarn#W:" .. warnings .. " %#StatusLine#")
	end
	return table.concat(parts, "")
end
opt.statusline = "%{%v:lua.SimpleStatusline()%}"

-- Per-split identifier winbar: makes it obvious which buffer/split you're in
-- when several are open side by side, with a modified indicator. (point 6)
function _G.SimpleWinbar()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "[No Name]"
	end
	local modified = vim.bo.modified and " ●" or ""
	return "  " .. filename .. modified .. "  "
end
opt.winbar = "%{%v:lua.SimpleWinbar()%}"

-- Keep the statusline diagnostic counts fresh without extra lag
vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter", "TextChanged", "InsertLeave" }, {
	callback = function()
		vim.cmd("redrawstatus")
	end,
})

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
vim.keymap.set("n", "<leader>mp", "<cmd>RenderMarkdown preview<CR>", { desc = "Open Terminal-Native Markdown Preview" })
vim.keymap.set("n", "<leader>mt", "<cmd>RenderMarkdown toggle<CR>", { desc = "Open Terminal-Native Markdown toggle" })

vim.keymap.set("n", "<leader>df", function()
	require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } })
end, { desc = "Diagnostics (Current File)" })

vim.keymap.set("n", "<leader>dw", function()
	require("trouble").toggle({ mode = "diagnostics" })
end, { desc = "Diagnostics (Workspace)" })

vim.keymap.set("t", "<C-Left>", [[<C-\><C-n><C-w>h]], { desc = "Navigate Left from Terminal" })
vim.keymap.set("t", "<C-Right>", [[<C-\><C-n><C-w>l]], { desc = "Navigate Right from Terminal" })
vim.keymap.set("t", "<C-Up>", [[<C-\><C-n><C-w>k]], { desc = "Navigate Upper from Terminal" })
vim.keymap.set("t", "<C-Down>", [[<C-\><C-n><C-w>j]], { desc = "Navigate Lower from Terminal" })
vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { desc = "Allow Ctrl+W window navigation inside terminal" })

-- VSCode-style indenting: select with Shift-V, tap Tab/Shift-Tab to indent
-- and stay in visual mode so you can keep pressing it. (point 5)
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
-- 5. MARKDOWN / NOTES QUALITY-OF-LIFE (point 7)
-- ========================================================================== --
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.conceallevel = 2 -- hides markup like Obsidian's live-preview
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
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

	vim.keymap.set("n", "<leader>lR", function()
		vim.diagnostic.reset(nil, bufnr)
		vim.cmd("LspRestart")
		vim.notify("LSP restarted for this buffer", vim.log.levels.INFO)
	end, { buffer = bufnr, desc = "Restart LSP (fix stuck diagnostics/errors)" })

	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
	end
end

-- ========================================================================== --
-- 8. PLUGIN SPECS
-- ========================================================================== --
require("lazy").setup({
	{ "j-hui/fidget.nvim", event = "VeryLazy", opts = {} },

	{
		"sainnhe/gruvbox-material",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.gruvbox_material_background = "hard"
			vim.g.gruvbox_material_foreground = "material"
			vim.g.gruvbox_material_enable_italic = 1
			vim.g.gruvbox_material_disable_italic_comment = 0
			vim.g.gruvbox_material_transparent_background = 2
			vim.g.gruvbox_material_dim_inactive_windows = 1
			vim.g.gruvbox_material_better_performance = 1 -- perf: skip a few cosmetic passes (point 10)

			vim.cmd.colorscheme("gruvbox-material")

			local hl = vim.api.nvim_set_hl
			hl(0, "Normal", { bg = "NONE" })
			hl(0, "NormalFloat", { bg = "NONE" })
			hl(0, "SignColumn", { bg = "NONE" })
			hl(0, "EndOfBuffer", { bg = "NONE" })
			hl(0, "@comment", { italic = false })
			hl(0, "Comment", { italic = false })
			hl(0, "@keyword", { bold = true })
			hl(0, "@type", { bold = true })
			hl(0, "@function", { bold = true })
		end,
	},

	{
		"romgrk/barbar.nvim",
		event = "VeryLazy", -- perf: don't block startup for the bufferline (point 10)
		dependencies = { "lewis6991/gitsigns.nvim", "nvim-tree/nvim-web-devicons" },
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {},
		version = "^1.0.0",
	},

	{ "windwp/nvim-autopairs", event = "InsertEnter", config = true },

	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "markdown" },
		config = function()
			require("render-markdown").setup({
				completions = { lsp = { enabled = true } },
				code = { style = "full", position = "left", width = "block", left_pad = 2, right_pad = 4 },
				pipe_table = { preset = "round" },
			})
		end,
	},

	-- Obsidian-style notes: wiki-links, backlinks, tags, daily notes,
	-- checkboxes - layered on top of render-markdown.nvim. (point 7)
	-- NOTE: update workspaces.path below to point at your real notes folder.
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		ft = "markdown",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			workspaces = {
				{ name = "notes", path = "~/notes" }, -- << set this to your notes directory
			},
			completion = {
				nvim_cmp = false,
				blink = true,
				min_chars = 2,
			},
			ui = { enable = false }, -- render-markdown.nvim already renders the UI
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
		end,
	},

	{ "nvim-treesitter/nvim-treesitter-textobjects" },

	{
		"smoka7/multicursors.nvim",
		event = "VeryLazy",
		dependencies = { "nvimtools/hydra.nvim" },
		opts = {},
		config = function(_, opts)
			require("multicursors").setup(opts)
			vim.keymap.set({ "n", "v" }, "<C-d>", function()
				vim.cmd("MCstart")
			end, { silent = true })
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
		-- Enriched git workflow (points 2 & 3):
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

			-- Point 2: current file across commits, two-pane, left editable / right preview
			vim.keymap.set("n", "<leader>gf", function()
				pcall(vim.cmd, "NvimTreeClose")
				vim.cmd("DiffviewFileHistory % --base=LOCAL")
			end, { desc = "File History (Two-Pane Diff)" })

			-- Point 3: visual-select lines, then see only those lines' history
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
				renderer = { icons = { show = { file = false, folder = false, folder_arrow = false, git = false } } },
				actions = {
					open_file = {
						quit_on_open = false,
						window_picker = {
							enable = true,
							picker = "default",
							chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
							exclude = {
								filetype = { "notify", "packer", "qf", "diff", "diffview", "fugitive" },
								buftype = { "nofile", "terminal", "help" },
							},
						},
					},
				},
				view = { width = 30 },
			})
			vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true, desc = "Toggle File Tree" })
		end,
	},

	-- Lean which-key guide (point 8): only top-level groups + the handful of
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
				{ "<leader>wq", "<C-w>c", desc = "Close Split" },
				{ "<leader>wo", "<C-w>o", desc = "Only This Window" },
				{ "<leader>w=", "<C-w>=", desc = "Equalize Splits" },
				{ "<leader>wx", "<cmd>vsplit<CR>", desc = "Vertical Split" },
				{ "<leader>ws", "<cmd>split<CR>", desc = "Horizontal Split" },
				{ "<leader>wn", "<cmd>BufferNext<CR>", desc = "Next Buffer" },
				{ "<leader>wp", "<cmd>BufferPrevious<CR>", desc = "Previous Buffer" },
				{ "<leader>ww", "<cmd>BufferPick<CR>", desc = "Pick Buffer" },
				{ "<leader>wl", "<cmd>BufferPin<CR>", desc = "Pin Buffer" },
				{ "<leader>wc", "<cmd>BufferClose<CR>", desc = "Close Buffer" },
				{ "<leader>gh", desc = "File History Log (Split)" },
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
			},
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
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "neovim/nvim-lspconfig" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			require("mason-lspconfig").setup({
				ensure_installed = { "rust_analyzer", "gopls", "lua_ls", "ts_ls", "bashls", "dockerls", "marksman" },
			})

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
				-- Point 9: you develop on macOS but target Linux, and libc /
				-- other unix-only crates don't resolve correctly if
				-- rust-analyzer assumes the host (mac) target. Pinning the
				-- cargo target to a Linux triple makes it analyze the
				-- project as if it were being built on Linux.
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
				gopls = {},
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
		"saghen/blink.cmp",
		version = "*",
		event = "InsertEnter", -- perf: only load once you actually start typing (point 10)
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

-- Point 4: this is the main fix for "weird errors that build up over hours".
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
