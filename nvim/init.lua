-- ========================================================================== --
-- [[                         STRUCTURED NVIM CONFIG                       ]] --
-- ========================================================================== --

-- 1. BASE SYSTEM SETTINGS (Performance & Behavioral adjustments)
vim.g.mapleader = " " -- Set Space bar as your 'Leader' key

local opt = vim.opt
opt.number = true -- Show line numbers
opt.relativenumber = true -- Relative line numbers
opt.termguicolors = true -- True color support
opt.clipboard = "unnamedplus" -- Share system clipboard natively
opt.signcolumn = "yes" -- Always show the sign column to prevent layout shifts
opt.updatetime = 300 -- Faster completion & hover diagnostic response time
opt.tabstop = 4 -- Render tabs as 4 spaces
opt.shiftwidth = 4 -- Number of spaces for auto-indentation
opt.expandtab = true -- Expand tabs into spaces

-- Prevent Neovim from automatically equalizing/resizing your panels when splitting
opt.equalalways = false

-- Configure Session Saver engine to preserve sizes and buffers perfectly
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"

local function diagnostic_short_message(message, max_len)
    local text = message:gsub("\n%s*", " "):gsub("%s+", " ")
    if #text > max_len then
        return text:sub(1, max_len - 3) .. "..."
    end
    return text
end

-- FIXED SHIFT+K INTERACTIVE HOVER DIALOG RE-ROUTING (CRASH-PROOF)
local function show_diagnostic_detail()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    if #vim.diagnostic.get(bufnr, { lnum = lnum }) == 0 then
        return false
    end

    -- 1. Safely generate the floating diagnostic canvas
    local _, float_win = vim.diagnostic.open_float(bufnr, {
        scope = "cursor",
        border = "rounded",
        focusable = true, -- Crucial: lets us jump inside
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        source = "always",
        severity_sort = true,
        prefix = function(_, i, total)
            return total > 1 and ("[" .. i .. "/" .. total .. "] ") or ""
        end,
    })

    -- 2. Validate that the window handle exists and is healthy before jumping focus
    if float_win and vim.api.nvim_win_is_valid(float_win) then
        vim.api.nvim_set_current_win(float_win)
        -- Instantly leave the dialog panel via 'q'
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
    else
        -- Fallback: Use standard window jump macro if the direct API reference fails
        local success, _ = pcall(vim.cmd, "wincmd p")
        if success and vim.bo.filetype == "lspinfo" or vim.bo.buftype == "nofile" then
            vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })
        end
    end
    return true
end

vim.diagnostic.config({
    virtual_text = {
        current_line = true,
        format = function(diagnostic)
            return diagnostic_short_message(diagnostic.message, 48)
        end,
        severity_sort = true,
        source = false,
        prefix = "",
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "●",
            [vim.diagnostic.severity.WARN] = "●",
            [vim.diagnostic.severity.INFO] = "●",
            [vim.diagnostic.severity.HINT] = "●",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticLineNrError",
            [vim.diagnostic.severity.WARN] = "DiagnosticLineNrWarn",
            [vim.diagnostic.severity.INFO] = "DiagnosticLineNrInfo",
            [vim.diagnostic.severity.HINT] = "DiagnosticLineNrHint",
        },
    },
    underline = { severity = { min = vim.diagnostic.severity.HINT } },
    float = { border = "rounded", source = "always", severity_sort = true },
    update_in_insert = true,
    severity_sort = true,
})

vim.api.nvim_set_hl(0, "DiagnosticLineNrError", { fg = "#f38ba8", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrWarn", { fg = "#fab387", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrInfo", { fg = "#89b4fa", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticLineNrHint", { fg = "#a6adc8", bold = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#f38ba8", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#fab387", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#89b4fa", italic = true })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#a6adc8", italic = true })

-- 2. GLOBAL INTUITIVE KEYMAPS (Works everywhere, no LSP dependency needed)

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

-- Direct directional navigation (Ctrl + Arrows)
vim.keymap.set("n", "<C-Left>", "<C-w>h", { desc = "Navigate to Left Window" })
vim.keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Navigate to Right Window" })
vim.keymap.set("n", "<C-Up>", "<C-w>k", { desc = "Navigate to Upper Window" })
vim.keymap.set("n", "<C-Down>", "<C-w>j", { desc = "Navigate to Lower Window" })

-- VS Code style Redo mapping (Ctrl + Shift + Z)
vim.keymap.set("n", "<C-S-z>", "<C-r>", { desc = "Redo Last Undo" })

-- Save session layout snapshot and Force Quit Neovim instantly (Ctrl + Q)
vim.keymap.set("n", "<C-q>", "<cmd>mksession! .nvim_session | qa!<CR>", { desc = "Save Session and Quit Instantly" })

-- Terminal-Native Live Markdown Preview Split (Space + m + p)
vim.keymap.set("n", "<leader>mp", "<cmd>RenderMarkdown preview<CR>", { desc = "Open Terminal-Native Markdown Preview" })

-- Structural Diagnostics Window Triggers
vim.keymap.set(
    "n",
    "<leader>df",
    "<cmd>Telescope diagnostics bufnr=0<CR>",
    { desc = "Fuzzy Find Current File Diagnostics" }
)
vim.keymap.set("n", "<leader>dw", "<cmd>Telescope diagnostics<CR>", { desc = "Fuzzy Find Workspace Diagnostics" })


-- THREE-PANEL DYNAMIC DIAGNOSTIC EXPLORER LAYOUT ENGINE
local function open_diagnostic_explorer()
    vim.cmd("NvimTreeClose")
    
    require("telescope.builtin").diagnostics({
        layout_strategy = "left_sidebar",
        layout_config = { width = 0.28 },
        attach_mappings = function(prompt_bufnr, map)
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            local function confirm_and_split_workspace()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if not selection then return end

                -- Panel B: Top-Right workspace (Focuses target file)
                vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
                local source_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_cursor(source_win, { selection.lnum + 1, selection.col })
                vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, silent = true })

                -- Panel C: Bottom-Right terminal log window (Diagnostic raw text layout)
                vim.cmd("belowright split")
                local diag_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_name(diag_buf, "Diagnostics Output Engine")
                
                local clean_message = "[" .. selection.type .. "] " .. selection.text:gsub("\n%s*", " ")
                vim.api.nvim_buf_set_lines(diag_buf, 0, -1, false, {
                    "==========================================================================",
                    "💥 CRITICAL DIAGNOSTIC ENTRY LOG",
                    "==========================================================================",
                    "📂 File: " .. selection.filename,
                    "📍 Location: Line " .. (selection.lnum + 1) .. ", Col " .. selection.col,
                    "--------------------------------------------------------------------------",
                    clean_message,
                    "==========================================================================",
                    "💡 Press 'q' inside this split layout array to terminate the buffer.",
                })
                
                vim.api.nvim_set_current_buf(diag_buf)
                vim.bo[diag_buf].modifiable = false
                vim.bo[diag_buf].buftype = "nofile"
                vim.cmd("resize 10") -- Keep bottom buffer thin and organized

                vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = diag_buf, silent = true })
                
                -- Bounce window workspace anchor back up to code panel automatically
                vim.api.nvim_set_current_win(source_win)
            end

            map("i", "<CR>", confirm_and_split_workspace)
            map("n", "<CR>", confirm_and_split_workspace)
            return true
        end,
    })
end
vim.keymap.set("n", "<leader>de", open_diagnostic_explorer, { desc = "Open 3-Panel Diagnostics Workspace" })


-- Smart Terminal Logic Function (Dynamic Horizontal/Vertical Routing)
local function open_smart_terminal()
    if vim.bo.filetype == "NvimTree" then
        vim.cmd("wincmd l")
    end

    local has_vertical_split = false
    local columns = {}

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        if ft ~= "NvimTree" and ft ~= "help" and ft ~= "qf" then
            local pos = vim.api.nvim_win_get_position(win)
            table.insert(columns, pos[2])
        end
    end

    if #columns > 1 then
        for i = 2, #columns do
            if columns[i] ~= columns[1] then
                has_vertical_split = true
                break
            end
        end
    end

    if has_vertical_split then
        vim.cmd("belowright split")
        vim.cmd("terminal")
    else
        vim.cmd("botright vsplit")
        local target_width = math.floor(vim.o.columns * 0.20)
        vim.cmd("vertical resize " .. target_width)
        vim.cmd("terminal")
    end
end
vim.keymap.set("n", "<leader>t", open_smart_terminal, { desc = "Open Layout-Aware Terminal" })

-- Terminal Mode Window Controls
vim.keymap.set("t", "<C-Left>", [[<C-\><C-n><C-w>h]], { desc = "Navigate Left from Terminal" })
vim.keymap.set("t", "<C-Right>", [[<C-\><C-n><C-w>l]], { desc = "Navigate Right from Terminal" })
vim.keymap.set("t", "<C-Up>", [[<C-\><C-n><C-w>k]], { desc = "Navigate Upper from Terminal" })
vim.keymap.set("t", "<C-Down>", [[<C-\><C-n><C-w>j]], { desc = "Navigate Lower from Terminal" })
vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { desc = "Allow Ctrl+W window navigation inside terminal" })

-- 3. AUTOMATIC PLUGIN MANAGER BOOTSTRAP (Zero-Setup Deployment)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", ts_builtin.lsp_references, opts)
    vim.keymap.set("n", "gi", ts_builtin.lsp_implementations, opts)
    vim.keymap.set("n", "gt", ts_builtin.lsp_type_definitions, opts)
    
    -- Linked dynamically to updated text-copy routing float window
    vim.keymap.set("n", "K", function()
        if not show_diagnostic_detail() then
            vim.lsp.buf.hover()
        end
    end, vim.tbl_extend("force", opts, { desc = "Shift+K: Diagnostic Detail or LSP Hover" }))
    
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
    vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<CR>", { buffer = bufnr, desc = "Restart LSP" })

    if client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
end

-- 4. PLUGIN DEFINITIONS & CONFIGURATIONS
require("lazy").setup({
    {
        "j-hui/fidget.nvim",
        opts = {},
    },
    {
        "ember-theme/nvim",
        name = "ember",
        priority = 1000,
        config = function()
            require("ember").setup({
                variant = "ember",
                styles = {
                    comments = { italic = true },
                    keywords = { bold = true },
                    types = { bold = true },
                },
                transparent = false,
                dark_variant = "ember",
            })
            vim.cmd("colorscheme ember")
        end,
    },
    {
        "romgrk/barbar.nvim",
        dependencies = {
            "lewis6991/gitsigns.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        init = function()
            vim.g.barbar_auto_setup = false
        end,
        opts = {},
        version = "^1.0.0",
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        ft = { "markdown" },
        config = function()
            require("render-markdown").setup({
                heading = {
                    sign = false,
                    icons = { "━ H1 ━ ", "─ H2 ─ ", "─ H3 ─ ", "─ H4 ─ " },
                },
                code = {
                    style = "full",
                    position = "left",
                    width = "block",
                    left_pad = 2,
                    right_pad = 4,
                },
                pipe_table = { preset = "round" },
            })
        end,
    },
    {
        "mg979/vim-visual-multi",
        init = function()
            vim.g.VM_maps = {
                ["Find Under"] = "<C-d>",
                ["Find Subword Under"] = "<C-d>",
            }
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search Files by Name" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search Text in Whole Project" })
            vim.keymap.set(
                "n",
                "<leader>fb",
                builtin.current_buffer_fuzzy_find,
                { desc = "Search Text in Current File" }
            )
        end,
    },
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {
            auto_close = false,
            open_no_results = true,
            height = 12,
            icons = {
                indent = {
                    top = "│ ",
                    middle = "├─ ",
                    last = "└─ ",
                    fold_open = "▼ ",
                    fold_closed = "▶ ",
                    ws = "  ",
                },
                kinds = {},
            },
            styles = { mode = { groups = { { "filename", "comment" } } } },
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
                file_history_panel = {
                    win_config = {
                        position = "bottom",
                        height = 16,
                    },
                },
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
                    file_history_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } } },
                },
            })

            local function open_commit_picker_diff()
                local has_telescope, telescope_builtin = pcall(require, "telescope.builtin")
                if not has_telescope then
                    vim.notify("Telescope core is required to load the Git Selector UI.", vim.log.levels.ERROR)
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
                    return
                end
            end

            vim.keymap.set("n", "<leader>gcc", open_commit_picker_diff, { desc = "Browse Commits & View Changed Files" })
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
                renderer = {
                    icons = { show = { file = false, folder = false, folder_arrow = false, git = false } },
                },
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
                { "<leader>de", desc = "Open 3-Panel Diagnostics Workspace" },
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
                rust = { "rustfmt" },
                go = { "gofmt" },
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
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            require("mason-lspconfig").setup({
                ensure_installed = {
                    "rust_analyzer",
                    "gopls",
                    "lua_ls",
                    "ts_ls",
                    "bashls",
                    "dockerls",
                    "marksman",
                },
            })

            local servers = {
                "rust_analyzer",
                "gopls",
                "lua_ls",
                "ts_ls",
                "bashls",
                "dockerls",
                "marksman",
            }

            for _, server in ipairs(servers) do
                vim.lsp.config(server, { capabilities = capabilities })
                vim.lsp.enable(server)
            end

            vim.lsp.config("ts_ls", {
                capabilities = capabilities,
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
            })
        end,
    },
    {
        "saghen/blink.cmp",
        version = "*",
        dependencies = {
            "rafamadriz/friendly-snippets",
            "onsails/lspkind.nvim",
        },
        opts = {
            keymap = {
                preset = "enter",
                ["<Tab>"] = { "select_next", "fallback" },
                ["<S-Tab>"] = { "select_prev", "fallback" },
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
            },
            signature = { enabled = true },
            sources = { default = { "lsp", "path", "snippets", "buffer" } },
            fuzzy = { implementation = "prefer_rust_with_warning" },
        },
        opts_extend = { "sources.default" },
    }
})

-- ========================================================================== --
-- [[              VS CODE STYLE DIAGNOSTICS & HOVER BOXES                 ]] --
-- ========================================================================== --

vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#545464", bg = "NONE", italic = true })

vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        if vim.bo.buftype ~= "" or vim.bo.filetype == "help" then
            return
        end
        -- Maintain automated lookups via base config
        local bufnr = vim.api.nvim_get_current_buf()
        local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
        if #vim.diagnostic.get(bufnr, { lnum = lnum }) > 0 then
            vim.diagnostic.open_float(bufnr, {
                scope = "cursor",
                border = "rounded",
                focusable = false, -- Background checks stay unfocused until Shift+K is hit
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
            vim.notify(client.name .. " ready", vim.log.levels.INFO)
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
