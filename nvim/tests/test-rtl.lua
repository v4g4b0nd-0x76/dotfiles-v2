assert(vim.fn.maparg("<leader>rt", "n") ~= "", "RTL toggle mapping must exist")
assert(vim.fn.exists(":RtlToggle") == 2, ":RtlToggle command must exist")

local path = "/tmp/dotfiles-rtl-test.txt"
vim.fn.writefile({ "سلام دنیا", "hello world" }, path)
vim.cmd("edit " .. vim.fn.fnameescape(path))

local buf = vim.api.nvim_get_current_buf()
assert(vim.wait(2000, function()
	return require("rtl").is_enabled(buf)
end), "RTL overlay must auto-enable for Farsi text")

-- Force a synchronous render instead of waiting for the 40ms debounce.
require("rtl").enable(buf)

local ns = vim.api.nvim_create_namespace("rtl")
local rows = {}
local overlay_text = ""
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
	rows[mark[2]] = true
	local vt = mark[4].virt_text
	if vt and vt[1] then
		overlay_text = vt[1][1]
	end
end

assert(rows[0] and not rows[1], "only the Persian line should be overlaid")
assert(overlay_text ~= "" and overlay_text ~= "سلام دنیا", "overlay must be reordered")

local has_presentation_form = false
for _, cp in ipairs(vim.fn.str2list(overlay_text)) do
	if cp >= 0xFB50 and cp <= 0xFEFF then
		has_presentation_form = true
	end
end
assert(has_presentation_form, "overlay must use Arabic Presentation Forms")

local overlay_hl = vim.api.nvim_get_hl(0, { name = "RtlOverlay", link = false })
assert(overlay_hl.fg == 0xD7D2C8, "overlay must use the paper foreground")

-- English-only text must not be overlaid.
local english_path = "/tmp/dotfiles-rtl-english.txt"
vim.fn.writefile({ "hello world" }, english_path)
vim.cmd("edit " .. vim.fn.fnameescape(english_path))
local english_buf = vim.api.nvim_get_current_buf()
vim.wait(200)
assert(not require("rtl").is_enabled(english_buf), "English-only buffers must not be overlaid")
