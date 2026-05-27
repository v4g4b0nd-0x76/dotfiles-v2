-- ========================================================================== --
-- [[                         STRUCTURED NVIM CONFIG                       ]] --
-- ========================================================================== --

-- 1. BASE SYSTEM SETTINGS (Performance & Behavioral adjustments)
vim.g.mapleader = " " -- Set Space bar as your 'Leader' key (used for shortcuts)

local opt = vim.opt
opt.number = true             -- Show line numbers
opt.relativenumber = true     -- Relative line numbers (great for jumping around)
opt.termguicolors = true      -- True color support
opt.clipboard = "unnamedplus" -- Share system clipboard natively (copy/paste to/from other apps)
opt.signcolumn = "yes"        -- Always show the sign column to prevent layout shifts
opt.updatetime = 300          -- Faster completion & hover diagnostic response time (VS Code feel)
opt.tabstop = 4               -- Render tabs as 4 spaces (Standard Rust style)
opt.shiftwidth = 4            -- Number of spaces for auto-indentation
opt.expandtab = true          -- Expand tabs into spaces

-- CRITICAL: Prevent Neovim from automatically equalizing/resizing your panels when splitting
opt.equalalways = false

-- Configure Session Saver engine to preserve sizes and buffers perfectly
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize"

-- 2. GLOBAL INTUITIVE KEYMAPS (Works everywhere, no LSP dependency needed)
-- Custom intuitive split bindings
vim.keymap.set("n", "|", "<cmd>vsplit<CR>", { desc = "Split Window Vertically" })
vim.keymap.set("n", "_", "<cmd>split<CR>", { desc = "Split Window Horizontally" })

-- Direct Tmux-style directional navigation (Ctrl + Arrows)
vim.keymap.set("n", "<C-Left>", "<C-w>h", { desc = "Navigate to Left Window" })
vim.keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Navigate to Right Window" })
vim.keymap.set("n", "<C-Up>", "<C-w>k", { desc = "Navigate to Upper Window" })
vim.keymap.set("n", "<C-Down>", "<C-w>j", { desc = "Navigate to Lower Window" })
vim.keymap.set({ "n", "t" }, "<C-q>", "<cmd>mksession! .nvim_session | qa!<CR>", { desc = "Save Session and Quit Instantly" })

-- VS Code style Redo mapping (Ctrl + Shift + Z)
vim.keymap.set("n", "<C-S-z>", "<C-r>", { desc = "Redo Last Undo" })

-- Force Quit Neovim instantly (Ctrl + Q) from anywhere (Normal or Terminal mode)
vim.keymap.set({ "n", "t" }, "<C-q>", "<cmd>wqa!<CR>", { desc = "Force Quit Neovim Instantly" })
-- Smart Terminal Logic Function (Dynamic Horizontal/Vertical Routing)
local function open_smart_terminal()
  -- If your cursor is currently sitting inside the file tree, jump out to the code area first
  if vim.bo.filetype == "NvimTree" then
    vim.cmd("wincmd l")
  end

  -- Scan window coordinates to see if a vertical split (side-by-side) already exists
  local has_vertical_split = false
  local columns = {}
  
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    -- Ignore layout shifts caused by sidebars, help menus, or quickfix lists
    if ft ~= "NvimTree" and ft ~= "help" and ft ~= "qf" then
      local pos = vim.api.nvim_win_get_position(win) -- returns {row, col}
      table.insert(columns, pos[2]) -- Track the horizontal starting column of the window
    end
  end

  -- If there are windows starting at different columns, a vertical split is active
  if #columns > 1 then
    for i = 2, #columns do
      if columns[i] ~= columns[1] then
        has_vertical_split = true
        break
      end
    end
  end

  -- Apply clean layout routing without destroying active buffers
  if has_vertical_split then
    -- Side-by-side view exists: Split the CURRENT panel horizontally for the terminal
    vim.cmd("belowright split")
    vim.cmd("terminal")
  else
    -- No side-by-side view: Open a fresh vertical layout on the far right at 20% width
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
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
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
    end,
  },

  -- Auto-close brackets and strings
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Native Terminal In-Buffer Markdown Engine (Obsidian Style rendering)
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
        pipe_table = {
          preset = "round",
        },
      })
    end,
  },

  -- Multi-line/Multi-word editing (VS Code Ctrl+D alternative)
  {
    "mg979/vim-visual-multi",
    init = function()
      vim.g.VM_maps = {
        ['Find Under'] = '<C-d>',
        ['Find Subword Under'] = '<C-d>',
      }
    end,
  },

  -- Fuzzy Search (Telescope)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Search Files by Name" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search Text in Whole Project" })
      vim.keymap.set("n", "<leader>fb", builtin.current_buffer_fuzzy_find, { desc = "Search Text in Current File" })
    end,
  },

  -- Simple File Tree Sidebar (No Icons, Toggleable)
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        renderer = {
          icons = {
            show = {
              file = false,
              folder = false,
              folder_arrow = false,
              git = false,
            },
          },
        },
        actions = {
          open_file = {
            quit_on_open = false,
            window_picker = {
              enable = true,
              picker = "default",
              chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
              exclude = {
                filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
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
        { "<leader>w", group = "Window Management" },
        { "<leader>wc", "<C-w>c", desc = "Close Current Split" },
        { "<leader>wo", "<C-w>o", desc = "Only Keep Current Window (Close Others)" },
        { "<leader>w=", "<C-w>=", desc = "Equalize Split Sizes" },
        { "<leader>wx", "<cmd>vsplit<CR>", desc = "Vertical Split" },
        { "<leader>ws", "<cmd>split<CR>", desc = "Horizontal Split" },
      })
    end,
  },

  -- LSP Core Configurations (Language Server Protocol)
  { "neovim/nvim-lspconfig" },

  -- Package Manager for LSPs (Automates downloading compilers/language servers)
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

      require("mason-lspconfig").setup({
        ensure_installed = { "rust_analyzer" },
      })

      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
      })
      vim.lsp.enable("rust_analyzer")
    end,
  },

  -- Completion Engine (IntelliSense Autocomplete dropdown)
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
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item() else fallback() end
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

-- Style the Inlay Hints globally (Make them dim and elegant)
vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#545464", bg = "NONE", italic = true })

-- 1. Automatically show inline warnings/errors in a floating box on hover
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

-- 2. Define standard IDE hotkeys when inside a codebase
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local opts = { buffer = ev.buf }
    local ts_builtin = require("telescope.builtin")

    -- MIDDLE POP-UP FUZZY SEARCH FOR CODE NAVIGATION
    vim.keymap.set("n", "gd", ts_builtin.lsp_definitions, opts)
    vim.keymap.set("n", "gr", ts_builtin.lsp_references, opts)

    -- STANDARD IDE OPERATORS
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

    -- Automatically turn on VS Code Style Inlay Hints for Variable Types
    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end

    -- Automatically run cargo fmt via the LSP on save
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

-- 3. Automate Terminal insert behavior adjustments
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
  pattern = "term://*",
  callback = function()
    vim.cmd("startinsert")
  end,
})

-- 4. PROJECT AUTOMATIC WORKSPACE SAVER & RESTORER
-- Save session state automatically when exiting
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    -- Avoid saving state if inside a transient git commit message editor
    if vim.bo.filetype ~= "gitcommit" then
      vim.cmd("mksession! .nvim_session")
    end
  end,
})

-- Restore session state automatically when launching
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    -- Only auto-restore panel layout if launched globally without passing specific files
    if vim.fn.argc() == 0 and vim.fn.filereadable(".nvim_session") == 1 then
      vim.cmd("source .nvim_session")
    end
  end,
})