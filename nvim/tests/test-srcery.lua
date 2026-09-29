assert(vim.g.colors_name == "srcery", "Neovim must load the Srcery colorscheme")

local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
assert(normal.bg == 0x121110, "Srcery must keep an opaque #121110 editor background")
