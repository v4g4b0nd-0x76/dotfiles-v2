-- ========================================================================== --
-- [[                        STRUCTURED NVIM CONFIG                        ]] --
-- ========================================================================== --

-- 1. BASE SYSTEM SETTINGS (Performance & Behavioral adjustments)
vim.g.mapleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"
opt.updatetime = 300
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.equalalways = false
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.hidden = true
vim.opt.autowrite = true

vim.api.nvim_set_hl(0, "DiagnosticLineNrError", { fg = "#f38ba8", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrWarn", { fg = "#fab387", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrInfo", { fg = "#89b4fa", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrHint", { fg = "#a6adc8", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#f38ba8", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#fab387", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#89b4fa", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#a6adc8", italic = true })

-- 2. GLOBAL INTUITIVE KEYMAPS
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
	require("trouble").toggle({
		mode = "diagnostics",
		filter = { buf = 0 },
	})
end)

vim.keymap.set("n", "<leader>dw", function()
	require("trouble").toggle({
		mode = "diagnostics",
	})
end)

vim.keymap.set("t", "<C-Left>", [[<C-\><C-n><C-w>h]], { desc = "Navigate Left from Terminal" })
vim.keymap.set("t", "<C-Right>", [[<C-\><C-n><C-w>l]], { desc = "Navigate Right from Terminal" })
vim.keymap.set("t", "<C-Up>", [[<C-\><C-n><C-w>k]], { desc = "Navigate Upper from Terminal" })
vim.keymap.set("t", "<C-Down>", [[<C-\><C-n><C-w>j]], { desc = "Navigate Lower from Terminal" })
vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { desc = "Allow Ctrl+W window navigation inside terminal" })

-- 3. AUTOMATIC PLUGIN MANAGER BOOTSTRAP
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then -- Updated vim.loop to modern vim.uv
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
		ts_builtin.lsp_references({
			include_declaration = false,
		})
	end, opts)
	vim.keymap.set("n", "gi", ts_builtin.lsp_implementations, opts)
	vim.keymap.set("n", "gt", ts_builtin.lsp_type_definitions, opts)

	vim.keymap.set("n", "K", function()
		local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })

		if #diagnostics > 0 then
			vim.diagnostic.open_float(nil, {
				focusable = true,
				border = "rounded",
				close_events = {
					"CursorMoved",
					-- "BufLeave",
				},
				source = "always",
			})
		else
			vim.lsp.buf.hover()
		end
	end, opts)

	-- vim.keymap.set("n", "K", function()
	-- 	local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
	--
	-- 	if #diagnostics > 0 then
	-- 		vim.diagnostic.open_float(nil, {
	-- 			focusable = true,
	-- 			border = "rounded",
	-- 			source = "always",
	-- 			close_events = {
	-- 				"CursorMoved",
	-- 				"CursorMovedI",
	-- 				"InsertEnter",
	-- 				"BufLeave",
	-- 				"FocusLost",
	-- 			},
	-- 		})
	-- 	else
	-- 		vim.lsp.buf.hover()
	-- 	end
	-- end, opts)

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

	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
	end
end

-- 4. PLUGIN DEFINITIONS & CONFIGURATIONS
require("lazy").setup({
	{ "j-hui/fidget.nvim", opts = {} },
	-- {
	--     "ember-theme/nvim",
	--     name = "ember",
	--     priority = 1000,
	--     config = function()
	--         require("ember").setup({
	--             variant = "ember",
	--             styles = {
	--                 comments = { italic = true },
	--                 keywords = { bold = true },
	--                 types = { bold = true },
	--             },
	--             transparent = false,
	--             dark_variant = "ember",
	--         })
	--         vim.cmd("colorscheme ember")
	--     end,
	-- },
	-- {
	-- 	"rebelot/kanagawa.nvim",
	-- 	priority = 1000,
	-- 	config = function()
	-- 		vim.opt.termguicolors = true
	-- 		vim.opt.background = "dark"
	--
	-- 		require("kanagawa").setup({
	-- 			theme = "dragon",
	-- 			transparent = false,
	-- 			dimInactive = false,
	-- 			terminalColors = true,
	-- 			compile = true,
	-- 			styles = {
	-- 				comments = { italic = true },
	-- 				keywords = { italic = true, bold = true },
	-- 				functions = { bold = true },
	-- 				variables = { bold = true },
	-- 				statements = { bold = true },
	-- 			},
	-- 			overrides = function(colors)
	-- 				return {
	-- 					Normal = { fg = colors.palette.dragonWhite, bg = colors.palette.dragonBlack0 },
	-- 				}
	-- 			end,
	-- 		})
	--
	-- 		vim.cmd.colorscheme("kanagawa-dragon")
	-- 	end,
	-- },
	--
	-- {
	-- 	"oskarnurm/koda.nvim",
	-- 	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	-- 	priority = 1000, -- make sure to load this before all the other start plugins
	-- 	config = function()
	-- 		-- require("koda").setup({ transparent = true })
	-- 		vim.cmd("colorscheme koda")
	-- 	end,
	-- },

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
			vim.g.gruvbox_material_better_performance = 0

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
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	{
		"smoka7/multicursors.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvimtools/hydra.nvim",
		},
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
		config = function()
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search Files by Name" })

			vim.keymap.set("n", "<leader>fg", function()
				require("grug-far").toggle_instance({
					instanceName = "search",
					prefills = {
						flags = "--fixed-strings",
					},
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
		opts = {
			windowCreationCommand = "vertical botright 50split",
			keymaps = {
				close = {
					n = "q",
				},
			},
		},
	},
	{
		"folke/trouble.nvim",
		opts = {
			auto_close = false,
			focus = true,
			win = {
				position = "right",
				size = 60,
			},
			preview = {
				type = "split",
				relative = "win",
				position = "bottom",
				size = 0.40,
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
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
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		config = function()
			require("diffview").setup({
				enhanced_diff_hl = true,
				use_icons = false,
				view = {
					default = { layout = "diff2_horizontal" },
					file_history = { layout = "diff2_horizontal" },
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

			vim.keymap.set(
				"n",
				"<leader>gcc",
				open_commit_picker_diff,
				{ desc = "Browse Commits & View Changed Files" }
			)
			vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Diff Workspace" })
			vim.keymap.set("n", "<leader>gco", git_checkout, { desc = "Git checkout changes" })
			vim.keymap.set("n", "<leader>gh", function()
				vim.cmd("NvimTreeClose")
				vim.cmd("DiffviewFileHistory --base=LOCAL %")
			end, { desc = "File History Log Split" })
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
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
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup()
			wk.add({
				{ "<leader>w", group = "Window Management" },
				{ "<leader>wq", "<C-w>c", desc = "Close Current Split" },
				{ "<leader>wo", "<C-w>o", desc = "Only Keep Current Window" },
				{ "<leader>w=", "<C-w>=", desc = "Equalize Split Sizes" },
				{ "<leader>wx", "<cmd>vsplit<CR>", desc = "Vertical Split" },
				{ "<leader>ws", "<cmd>split<CR>", desc = "Horizontal Split" },
				{ "<leader>wn", "<cmd>BufferNext<CR>", noremap = true, silent = true, desc = "Next Tab" },
				{ "<leader>wp", "<cmd>BufferPrevious<CR>", noremap = true, silent = true, desc = "Previous Tab" },
				{ "<leader>ww", "<cmd>BufferPick<CR>", noremap = true, silent = true, desc = "Select Tab" },
				{ "<leader>wl", "<cmd>BufferPin<CR>", noremap = true, silent = true, desc = "Pin Tab" },
				{ "<leader>wc", "<cmd>BufferClose<CR>", noremap = true, silent = true, desc = "Close Tab" },
				{ "<leader>m", group = "Markdown" },
				{ "<leader>d", group = "Structural Diagnostics" },
				{ "<leader>f", group = "Fuzzy Finder" },
				{ "<leader>g", group = "GIT" },
				{ "<leader>l", group = "lsp" },
				{ "<leader>gc", desc = "Browse Commits & View Changed Files" },
				{ "<leader>gd", group = "Diff Evaluation Engine" },
			})
		end,
	},
	{ "neovim/nvim-lspconfig" },
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				javascript = { "prettierd" },
				javascriptreact = { "prettierd" },
				rust = { "rustfmt", lsp_format = "fallback" },
				lua = { "stylua" },

				c = { "clang-format" }, -- Added C since you write system languages
				sh = { "shfmt" },
				markdown = { "prettierd" },
			},
		},
	},
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
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
				rust_analyzer = {
					cargo = {
						target = "x86_64-unknown-linux-gnu",
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
				list = {
					selection = { preselect = true, auto_insert = false },
				},
			},
			signature = { enabled = true },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
})

-- ========================================================================== --
-- [[             VS CODE STYLE DIAGNOSTICS & HOVER BOXES                 ]] --
-- ========================================================================== --

vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#545464", bg = "NONE", italic = true })

vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		if vim.bo.buftype ~= "" or vim.bo.filetype == "help" then
			return
		end

		-- Prevent flickering/lag by ensuring we don't open if a float is already active
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
local function focus_editor()
    -- close known sidebars
    pcall(vim.cmd, "NvimTreeClose")
    pcall(vim.cmd, "TroubleClose")
    pcall(vim.cmd, "DiffviewClose")
    pcall(vim.cmd, "GrugFarClose")

    -- close floating windows
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative ~= "" then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end

    -- switch to a normal file window
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local bt = vim.bo[buf].buftype
        local ft = vim.bo[buf].filetype

        if bt == ""
            and ft ~= "NvimTree"
            and ft ~= "trouble"
            and ft ~= "grug-far"
            and not ft:match("^Diffview") then
            vim.api.nvim_set_current_win(win)
            break
        end
    end

    -- remove every split
    vim.cmd("only")
end

vim.keymap.set("n", "<leader>wf", focus_editor, {
    desc = "Focus Editor",
})
