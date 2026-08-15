-- Kuro Nezumi: soot black, ash gray, worn paper, signal red.
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "kuro_nezumi"

local c = {
	ink = "#080808", ink_alt = "#101010", surface = "#171717",
	raised = "#202020", border = "#343434", paper = "#d7d2c8",
	soft = "#9a948a", muted = "#6f6a63", red = "#b73535",
	red_hi = "#d94a4a", selection = "#2a1818", green = "#8a8f73",
	yellow = "#b8a781", blue = "#8c9097", cyan = "#7f9693",
}
local hl = vim.api.nvim_set_hl
local function set(group, opts) hl(0, group, opts) end

-- Leave normal editing cells transparent so Ghostty's scanline texture remains
-- visible. Deliberate UI surfaces below keep their quiet solid backgrounds.
set("Normal", { fg = c.paper, bg = "NONE" })
set("NormalFloat", { fg = c.paper, bg = c.surface })
set("FloatBorder", { fg = c.border, bg = c.surface })
set("ColorColumn", { bg = c.raised })
set("Cursor", { fg = c.ink, bg = c.paper })
set("CursorLine", { bg = c.ink_alt })
set("CursorLineNr", { fg = c.paper, bg = c.ink_alt, bold = true })
set("LineNr", { fg = c.muted, bg = "NONE" })
set("SignColumn", { bg = "NONE" })
set("EndOfBuffer", { fg = c.ink, bg = "NONE" })
set("NonText", { fg = c.border, bg = "NONE" })
set("Visual", { bg = c.selection })
set("Search", { fg = c.paper, bg = c.red })
set("IncSearch", { fg = c.ink, bg = c.red_hi, bold = true })
set("MatchParen", { fg = c.red_hi, bold = true })
set("WinSeparator", { fg = c.border })
set("StatusLine", { fg = c.paper, bg = c.raised })
set("StatusLineNC", { fg = c.muted, bg = c.surface })
set("TabLine", { fg = c.muted, bg = c.surface })
set("TabLineSel", { fg = c.paper, bg = c.raised, bold = true })
set("Pmenu", { fg = c.soft, bg = c.surface })
set("PmenuSel", { fg = c.paper, bg = c.selection })
set("Comment", { fg = c.muted, italic = false })
set("Constant", { fg = c.yellow })
set("String", { fg = c.yellow })
set("Character", { fg = c.yellow })
set("Number", { fg = c.yellow })
set("Boolean", { fg = c.yellow })
set("Identifier", { fg = c.paper })
set("Function", { fg = c.cyan })
set("Statement", { fg = c.red_hi, bold = true })
set("Keyword", { fg = c.red_hi, bold = true })
set("Conditional", { fg = c.red_hi, bold = true })
set("Repeat", { fg = c.red_hi, bold = true })
set("Operator", { fg = c.soft })
set("Type", { fg = c.blue, bold = true })
set("Special", { fg = c.soft })
set("Todo", { fg = c.ink, bg = c.red_hi, bold = true })
set("Error", { fg = c.red_hi, bold = true })
set("DiagnosticError", { fg = c.red_hi })
set("DiagnosticWarn", { fg = c.yellow })
set("DiagnosticInfo", { fg = c.blue })
set("DiagnosticHint", { fg = c.cyan })
set("DiagnosticVirtualTextError", { fg = c.red_hi, bg = c.selection })
set("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = c.ink_alt })
set("DiagnosticVirtualTextInfo", { fg = c.blue, bg = c.ink_alt })
set("DiagnosticVirtualTextHint", { fg = c.cyan, bg = c.ink_alt })
set("DiffAdd", { fg = c.green, bg = c.ink_alt })
set("DiffChange", { fg = c.yellow, bg = c.ink_alt })
set("DiffDelete", { fg = c.red_hi, bg = c.ink_alt })
set("GitSignsAdd", { fg = c.green })
set("GitSignsChange", { fg = c.yellow })
set("GitSignsDelete", { fg = c.red_hi })
set("WinBar", { fg = c.paper, bg = c.raised, bold = true })
set("WinBarNC", { fg = c.muted, bg = c.surface })

return c
