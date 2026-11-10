assert(vim.g.colors_name == "kuro_nezumi", "Neovim must load the Kuro Nezumi colorscheme")

local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
assert(normal.bg == 0x080808, "Kuro Nezumi must use an opaque #080808 editor background")

local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
assert(comment.fg == 0x6F6A63, "comments must use muted ash")
