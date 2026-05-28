-- ========================================================================== --
-- [[                         STRUCTURED NVIM CONFIG                       ]] --
-- ========================================================================== --

-- 1. BASE SYSTEM SETTINGS (Performance & Behavioral adjustments)
vim.g.mapleader = " " -- Set Space bar as your 'Leader' key

local opt = vim.opt
opt.number = true             -- Show line numbers
opt.relativenumber = true     -- Relative line numbers
opt.termguicolors = true      -- True color support
opt.clipboard = "unnamedplus" -- Share system clipboard natively
opt.signcolumn = "yes"        -- Always show the sign column to prevent layout shifts
opt.updatetime = 300          -- Faster completion & hover diagnostic response time
opt.tabstop = 4               -- Render tabs as 4 spaces
opt.shiftwidth = 4            -- Number of spaces for auto-indentation
opt.expandtab = true          -- Expand tabs into spaces

-- Prevent Neovim from automatically equalizing/resizing your panels when splitting
opt.equalalways = false

-- Configure Session Saver engine to preserve sizes and buffers perfectly
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"

-- 2. GLOBAL INTUITIVE KEYMAPS (Works everywhere, no LSP dependency needed)
vim.keymap.set("n", "|", "<cmd>vsplit<CR>", { desc = "Split Window Vertically" })
vim.keymap.set("n", "_", "<cmd>split<CR>", { desc = "Split Window Horizontally" })

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

-- Structural Diagnostics Window Triggers (Routing to Telescope Fuzzy Finder)
vim.keymap.set(
    "n",
    "<leader>df",
    "<cmd>Telescope diagnostics bufnr=0<CR>",
    { desc = "Fuzzy Find Current File Diagnostics" }
)
vim.keymap.set("n", "<leader>dw", "<cmd>Telescope diagnostics<CR>", { desc = "Fuzzy Find Workspace Diagnostics" })

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

-- 4. PLUGIN DEFINITIONS & CONFIGURATIONS
require("lazy").setup({

    -- Theme: Kanagawa (Dark, High-Contrast Dragon Variant)
    {
        "rebelot/kanagawa.nvim",
        priority = 1000,
        config = function()
            require("kanagawa").setup({
                compile = false,
                undercurl = true,
                commentStyle = { italic = true },
                keywordStyle = { italic = true },
                statementStyle = { bold = true },
                transparent = false,
                dimInactive = false,
                terminalColors = true,
                theme = "dragon",
                background = { dark = "dragon" },
            })
            vim.cmd("colorscheme kanagawa")

            -- HIGH-VISIBILITY EXTRA DIFF COLOR PACK (Deep Contrast Background Highlights)
            vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1d3522", fg = "NONE" })      -- Deep green background for new code
            vim.api.nvim_set_hl(0, "DiffChange", { bg = "#182638", fg = "NONE" })   -- Deep indigo background for altered blocks
            vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3d1b1b", fg = "#5c2424" }) -- Deep crimson background for deleted lines
            vim.api.nvim_set_hl(0, "DiffText", { bg = "#284566", fg = "NONE", bold = true }) -- Vibrant blue for inline granular shifts
        end,
    },

    -- Auto-close brackets and strings
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Native Terminal In-Buffer Markdown Engine
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

    -- Multi-line/Multi-word editing (VS Code Ctrl+D alternative)
    {
        "mg979/vim-visual-multi",
        init = function()
            vim.g.VM_maps = {
                ["Find Under"] = "<C-d>",
                ["Find Subword Under"] = "<C-d>",
            }
        end,
    },

    -- Fuzzy Search Layer (Telescope)
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

    -- VS Code Style Diagnostics Tree Explorer Panel
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

    -- VS Code Style Left Gutter Changed Lines Highlighting
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

    -- Git Diff Workspace & History Resolver Panel
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
        config = function()
            require("diffview").setup({
                enhanced_diff_hl = true,
                use_icons = false,
                view = {
                    default = { layout = "diff2_horizontal" },
                    file_history = { layout = "diff2_horizontal" }, -- Main side-by-side columns template
                    merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
                },
                file_history_panel = {
                    win_config = {
                        position = "bottom", -- Anchors selection layout arrays across the bottom threshold
                        height = 16,
                    },
                },
                hooks = {
                    diff_buf_win_enter = function(bufnr, winid, ctx)
                        -- Complete bypass of all folding architectures
                        vim.wo[winid].foldenable = false
                        vim.wo[winid].foldmethod = "manual"

                        -- SIDEBAR ALIGNMENT HACK: Forces your active, modifiable code workspace to the Left Column,
                        -- naturally locking the read-only file history snapshot and commit selectors horizontally on the Right.
                        if ctx and ctx.view and ctx.view.type == "file_history" and vim.bo[bufnr].modifiable then
                            vim.api.nvim_win_call(winid, function()
                                vim.cmd("wincmd H")
                            end)
                        end
                    end,
                },
                keymaps = {
                    view = {
                        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } },
                    },
                    file_panel = {
                        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } },
                    },
                    file_history_panel = {
                        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Exit Diff Workspace Instantly" } },
                    },
                },
            })

            -- INTERACTIVE COMMIT PICKER ENGINE (Links Telescope log directly to a isolated Diffview instance)
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
                                -- Closes file trees to keep window split geometry pristine
                                vim.cmd("NvimTreeClose")
                                -- revision notation range config (hash~1..hash) isolates changes introduced solely by that commit
                                vim.cmd("DiffviewOpen " .. selection.value .. "~1.." .. selection.value)
                            end
                        end)
                        return true
                    end,
                })
            end
            local function git_add_and_commit_prompt()
                vim.ui.input({ prompt = "💾 Enter Git Commit Message: " }, function(msg)
                    if not msg or msg == "" then
                        vim.notify("Git operation cancelled: Empty message block.", vim.log.levels.WARN)
                        return
                    end

                    -- Stage local tree working files safely
                    local add_out = vim.fn.system("git add .")
                    if vim.v.shell_error ~= 0 then
                        vim.notify("Git Add Failed:\n" .. add_out, vim.log.levels.ERROR)
                        return
                    end

                    -- Sanitize incoming text bounds to block literal bash breaking characters
                    local escaped_msg = msg:gsub("'", "'\\''")
                    local commit_out = vim.fn.system(string.format("git commit -m '%s'", escaped_msg))

                    if vim.v.shell_error ~= 0 then
                        vim.notify("Git Commit Failed:\n" .. commit_out, vim.log.levels.ERROR)
                    else
                        vim.notify("Changes successfully staged and committed!\n" .. msg, vim.log.levels.INFO)
                    end
                end)
            end
            -- FIXED SHORTCUTS
            vim.keymap.set("n", "<leader>gc", open_commit_picker_diff, { desc = "Browse Commits & View Changed Files" })
            vim.keymap.set("n", "<leader>gdc", "<cmd>DiffviewClose<CR>", { desc = "Close Diff Workspace" })
            vim.keymap.set("n", "<leader>ga", git_add_and_commit_prompt, { desc = "Git Add All & Commit Prompt" })

            vim.keymap.set("n", "<leader>gh", function()
                vim.cmd("NvimTreeClose")
                vim.cmd("DiffviewFileHistory --base=LOCAL %")
            end, { desc = "File History Log Split" })
        end,
    },

    -- Simple File Tree Sidebar
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

    -- Shortcut Helper Configuration
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            local wk = require("which-key")
            wk.setup()
            wk.add({
                { "<leader>w",  group = "Window Management" },
                { "<leader>wc", "<C-w>c",                                    desc = "Close Current Split" },
                { "<leader>wo", "<C-w>o",                                    desc = "Only Keep Current Window" },
                { "<leader>w=", "<C-w>=",                                    desc = "Equalize Split Sizes" },
                { "<leader>wx", "<cmd>vsplit<CR>",                           desc = "Vertical Split" },
                { "<leader>ws", "<cmd>split<CR>",                            desc = "Horizontal Split" },
                { "<leader>m",  group = "Markdown Utilities" },
                { "<leader>d",  group = "Structural Diagnostics" },
                { "<leader>g",  group = "Advanced Git Toolkit" },
                { "<leader>gc", desc = "Browse Commits & View Changed Files" },
                { "<leader>gd", group = "Diff Evaluation Engine" },
            })
        end,
    },

    -- LSP Core Configurations
    { "neovim/nvim-lspconfig" },

    -- Package Manager for LSPs
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup()
        end,
    },

    -- Bridge between Mason and lspconfig
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            require("mason-lspconfig").setup({ ensure_installed = { "rust_analyzer" } })
            vim.lsp.config("rust_analyzer", { capabilities = capabilities })
            vim.lsp.enable("rust_analyzer")
        end,
    },

    -- Completion Engine
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },
})

-- ========================================================================== --
-- [[              VS CODE STYLE DIAGNOSTICS & HOVER BOXES                 ]] --
-- ========================================================================== --

vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#545464", bg = "NONE", italic = true })

vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        local opts = {
            focusable = false,
            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
            border = "rounded",
            source = "always",
            prefix = " ",
            scope = "cursor",
        }
        vim.diagnostic.open_float(nil, opts)
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local opts = { buffer = ev.buf }
        local ts_builtin = require("telescope.builtin")

        vim.keymap.set("n", "gd", ts_builtin.lsp_definitions, opts)
        vim.keymap.set("n", "gr", ts_builtin.lsp_references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end

        if client and client:supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = ev.buf,
                callback = function()
                    vim.lsp.buf.format({ bufnr = ev.buf, id = client.id })
                end,
            })
        end
    end,
})

vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
    pattern = "term://*",
    callback = function()
        vim.cmd("startinsert")
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if vim.bo.filetype ~= "gitcommit" then
            vim.cmd("mksession! .nvim_session")
        end
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
