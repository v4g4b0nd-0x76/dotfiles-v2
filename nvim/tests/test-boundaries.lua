vim.cmd("enew!")
vim.bo.filetype = "typescript"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
	"interface Outer {",
	"  run() {",
	"    if (ready) {",
	"      work()",
	"    }",
	"  }",
	"}",
})

vim.api.nvim_win_set_cursor(0, { 4, 6 })
vim.cmd("normal ][")
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 5, 4 }), "][ must stop at the matching closing brace")

vim.cmd("normal []")
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 3, 15 }), "[] must stop at the matching opening brace")
