-- Kuro Nezumi: soot black, ash gray, worn paper, signal red.
-- Neovim's own palette, deliberately independent of the terminal theme.
-- Tokens mirror kuro-nezumi-palette.md / doom/themes/kuro-nezumi-theme.el.

local c = {
	ink = "#080808",
	ink_alt = "#101010",
	surface = "#171717",
	raised = "#202020",
	border = "#343434",
	paper = "#D7D2C8",
	soft = "#9A948A",
	muted = "#6F6A63",
	signal = "#B73535",
	alert = "#D94A4A",
	moss = "#8A8F73",
	brass = "#B8A781",
	steel = "#8C9097",
	oxide = "#7F9693",
	selection = "#2A1818",
}

local function hl(group, opts)
	vim.api.nvim_set_hl(0, group, opts)
end

local function link(group, target)
	vim.api.nvim_set_hl(0, group, { link = target })
end

vim.o.background = "dark"
vim.o.termguicolors = true
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.g.colors_name = "kuro_nezumi"

-- Terminal palette so `:terminal` matches the editor.
local terminal = {
	c.ink_alt,
	c.alert,
	c.moss,
	c.brass,
	c.steel,
	c.soft,
	c.oxide,
	c.paper,
	c.muted,
	c.signal,
	c.moss,
	c.brass,
	c.steel,
	c.soft,
	c.oxide,
	c.paper,
}
for i, color in ipairs(terminal) do
	vim.g["terminal_color_" .. (i - 1)] = color
end

-- Editor chrome -------------------------------------------------------------
hl("Normal", { fg = c.paper, bg = c.ink })
hl("NormalNC", { fg = c.soft, bg = c.ink })
hl("NormalFloat", { fg = c.paper, bg = c.surface })
hl("FloatBorder", { fg = c.border, bg = c.surface })
hl("FloatTitle", { fg = c.alert, bg = c.surface, bold = true })
hl("FloatFooter", { fg = c.muted, bg = c.surface })

hl("Cursor", { fg = c.ink, bg = c.paper })
hl("TermCursor", { fg = c.ink, bg = c.paper })
hl("CursorLine", { bg = c.ink_alt })
hl("CursorColumn", { bg = c.ink_alt })
hl("ColorColumn", { bg = c.ink_alt })
hl("CursorLineNr", { fg = c.paper, bg = c.ink_alt, bold = true })
hl("LineNr", { fg = c.muted })
hl("LineNrAbove", { fg = c.muted })
hl("LineNrBelow", { fg = c.muted })
hl("SignColumn", { bg = c.ink })
hl("FoldColumn", { fg = c.muted, bg = c.ink })
hl("Folded", { fg = c.soft, bg = c.surface })
hl("VertSplit", { fg = c.border, bg = c.ink })
hl("WinSeparator", { fg = c.border, bg = c.ink })

hl("StatusLine", { fg = c.paper, bg = c.raised })
hl("StatusLineNC", { fg = c.muted, bg = c.surface })
hl("WinBar", { fg = c.muted, bg = c.ink })
hl("WinBarNC", { fg = c.muted, bg = c.ink })
hl("TabLine", { fg = c.muted, bg = c.surface })
hl("TabLineSel", { fg = c.paper, bg = c.raised, bold = true })
hl("TabLineFill", { bg = c.ink })

hl("Pmenu", { fg = c.paper, bg = c.surface })
hl("PmenuSel", { fg = c.paper, bg = c.selection, bold = true })
hl("PmenuSbar", { bg = c.raised })
hl("PmenuThumb", { bg = c.border })
hl("PmenuMatch", { fg = c.alert, bold = true })
hl("PmenuMatchSel", { fg = c.alert, bold = true })

hl("Visual", { bg = c.selection })
hl("VisualNOS", { bg = c.selection })
hl("Search", { fg = c.ink, bg = c.brass })
hl("IncSearch", { fg = c.ink, bg = c.alert })
hl("CurSearch", { fg = c.ink, bg = c.signal, bold = true })
hl("MatchParen", { fg = c.alert, bold = true })
hl("QuickFixLine", { bg = c.selection })

hl("Directory", { fg = c.oxide, bold = true })
hl("Title", { fg = c.alert, bold = true })
hl("Question", { fg = c.oxide })
hl("MoreMsg", { fg = c.oxide })
hl("ModeMsg", { fg = c.paper, bold = true })
hl("WarningMsg", { fg = c.alert })
hl("ErrorMsg", { fg = c.alert, bold = true })
hl("NonText", { fg = c.border })
hl("EndOfBuffer", { fg = c.ink })
hl("SpecialKey", { fg = c.muted })
hl("Whitespace", { fg = c.border })
hl("Conceal", { fg = c.muted })
hl("MsgArea", { fg = c.paper, bg = c.ink })

hl("SpellBad", { sp = c.alert, undercurl = true })
hl("SpellCap", { sp = c.oxide, undercurl = true })
hl("SpellRare", { sp = c.brass, undercurl = true })
hl("SpellLocal", { sp = c.steel, undercurl = true })

-- Syntax --------------------------------------------------------------------
hl("Comment", { fg = c.muted, italic = true })
hl("Constant", { fg = c.brass })
hl("String", { fg = c.brass })
hl("Character", { fg = c.brass })
hl("Number", { fg = c.brass })
hl("Float", { fg = c.brass })
hl("Boolean", { fg = c.brass })
hl("Identifier", { fg = c.paper })
hl("Function", { fg = c.oxide })
hl("Statement", { fg = c.alert, bold = true })
hl("Conditional", { fg = c.alert, bold = true })
hl("Repeat", { fg = c.alert, bold = true })
hl("Label", { fg = c.alert })
hl("Operator", { fg = c.soft })
hl("Keyword", { fg = c.alert, bold = true })
hl("Exception", { fg = c.alert, bold = true })
hl("PreProc", { fg = c.soft })
hl("Include", { fg = c.alert })
hl("Define", { fg = c.alert })
hl("Macro", { fg = c.oxide })
hl("PreCondit", { fg = c.soft })
hl("Type", { fg = c.steel, bold = true })
hl("StorageClass", { fg = c.steel, bold = true })
hl("Structure", { fg = c.steel, bold = true })
hl("Typedef", { fg = c.steel, bold = true })
hl("Special", { fg = c.soft })
hl("SpecialChar", { fg = c.brass })
hl("Tag", { fg = c.oxide })
hl("Delimiter", { fg = c.soft })
hl("SpecialComment", { fg = c.muted, italic = true })
hl("Debug", { fg = c.alert })
hl("Underlined", { underline = true })
hl("Bold", { bold = true })
hl("Italic", { italic = true })
hl("Ignore", { fg = c.ink })
hl("Error", { fg = c.alert })
hl("Todo", { fg = c.ink, bg = c.brass, bold = true })

-- Diff / git ----------------------------------------------------------------
hl("DiffAdd", { bg = "#0F1A10", fg = c.moss })
hl("DiffChange", { bg = "#1A1710", fg = c.brass })
hl("DiffDelete", { bg = "#1A1010", fg = c.alert })
hl("DiffText", { bg = "#2A2418", fg = c.paper, bold = true })
hl("Added", { fg = c.moss })
hl("Changed", { fg = c.brass })
hl("Removed", { fg = c.alert })
hl("GitSignsAdd", { fg = c.moss })
hl("GitSignsChange", { fg = c.brass })
hl("GitSignsDelete", { fg = c.alert })

-- Diagnostics ---------------------------------------------------------------
hl("DiagnosticError", { fg = c.alert })
hl("DiagnosticWarn", { fg = c.brass })
hl("DiagnosticInfo", { fg = c.steel })
hl("DiagnosticHint", { fg = c.oxide })
hl("DiagnosticOk", { fg = c.moss })
hl("DiagnosticDeprecated", { fg = c.muted, strikethrough = true })
hl("DiagnosticUnnecessary", { fg = c.muted })

hl("DiagnosticVirtualTextError", { fg = c.alert, bg = "#1A1010" })
hl("DiagnosticVirtualTextWarn", { fg = c.brass, bg = "#1A1710" })
hl("DiagnosticVirtualTextInfo", { fg = c.steel, bg = "#101418" })
hl("DiagnosticVirtualTextHint", { fg = c.oxide, bg = "#101616" })
hl("DiagnosticVirtualTextOk", { fg = c.moss, bg = "#0F1A10" })

hl("DiagnosticUnderlineError", { sp = c.alert, undercurl = true })
hl("DiagnosticUnderlineWarn", { sp = c.brass, undercurl = true })
hl("DiagnosticUnderlineInfo", { sp = c.steel, undercurl = true })
hl("DiagnosticUnderlineHint", { sp = c.oxide, undercurl = true })
hl("DiagnosticUnderlineOk", { sp = c.moss, undercurl = true })

hl("DiagnosticFloatingError", { fg = c.alert })
hl("DiagnosticFloatingWarn", { fg = c.brass })
hl("DiagnosticFloatingInfo", { fg = c.steel })
hl("DiagnosticFloatingHint", { fg = c.oxide })
hl("DiagnosticFloatingOk", { fg = c.moss })

hl("DiagnosticSignError", { fg = c.alert })
hl("DiagnosticSignWarn", { fg = c.brass })
hl("DiagnosticSignInfo", { fg = c.steel })
hl("DiagnosticSignHint", { fg = c.oxide })
hl("DiagnosticSignOk", { fg = c.moss })

-- LSP -----------------------------------------------------------------------
hl("LspReferenceText", { bg = c.raised })
hl("LspReferenceRead", { bg = c.raised })
hl("LspReferenceWrite", { bg = c.raised, underline = true })
hl("LspInlayHint", { fg = c.muted, italic = true })
hl("LspSignatureActiveParameter", { fg = c.alert, bold = true })
hl("LspCodeLens", { fg = c.muted, italic = true })

-- Treesitter ----------------------------------------------------------------
link("@comment", "Comment")
link("@keyword", "Keyword")
link("@keyword.function", "Keyword")
link("@keyword.return", "Keyword")
link("@keyword.operator", "Operator")
link("@conditional", "Conditional")
link("@repeat", "Repeat")
link("@variable", "Identifier")
link("@variable.builtin", "Special")
link("@variable.parameter", "Identifier")
link("@variable.member", "Identifier")
link("@function", "Function")
link("@function.builtin", "Special")
link("@function.call", "Function")
link("@function.method", "Function")
link("@string", "String")
link("@string.escape", "SpecialChar")
link("@string.special", "SpecialChar")
link("@number", "Number")
link("@boolean", "Boolean")
link("@type", "Type")
link("@type.builtin", "Type")
link("@constant", "Constant")
link("@constant.builtin", "Constant")
link("@operator", "Operator")
link("@property", "Identifier")
link("@field", "Identifier")
link("@parameter", "Identifier")
link("@namespace", "Type")
link("@module", "Type")
link("@attribute", "Special")
link("@label", "Label")
link("@punctuation.delimiter", "Delimiter")
link("@punctuation.bracket", "Delimiter")
link("@tag", "Tag")
link("@tag.attribute", "Special")
link("@tag.delimiter", "Delimiter")
link("@text.title", "Title")
link("@text.literal", "String")
link("@text.reference", "Directory")
link("@markup.link", "Directory")
link("@markup.raw", "String")
link("@markup.strong", "Bold")
link("@markup.italic", "Italic")
link("@diff.plus", "Added")
link("@diff.minus", "Removed")
link("@diff.delta", "Changed")
link("@diagnostic.error", "DiagnosticError")
link("@diagnostic.warn", "DiagnosticWarn")
link("@diagnostic.info", "DiagnosticInfo")
link("@diagnostic.hint", "DiagnosticHint")

-- Telescope -----------------------------------------------------------------
hl("TelescopeNormal", { fg = c.paper, bg = c.surface })
hl("TelescopeBorder", { fg = c.border, bg = c.surface })
hl("TelescopePromptNormal", { fg = c.paper, bg = c.surface })
hl("TelescopePromptBorder", { fg = c.border, bg = c.surface })
hl("TelescopePromptPrefix", { fg = c.signal, bold = true })
hl("TelescopePromptTitle", { fg = c.ink, bg = c.brass, bold = true })
hl("TelescopePreviewTitle", { fg = c.ink, bg = c.moss, bold = true })
hl("TelescopeResultsTitle", { fg = c.ink, bg = c.oxide, bold = true })
hl("TelescopeSelection", { fg = c.paper, bg = c.selection, bold = true })
hl("TelescopeSelectionCaret", { fg = c.alert, bg = c.selection })
hl("TelescopeMatching", { fg = c.alert, bold = true })

-- Trouble -------------------------------------------------------------------
hl("TroubleNormal", { fg = c.paper, bg = c.surface })
hl("TroubleNormalNC", { fg = c.soft, bg = c.surface })
hl("TroubleText", { fg = c.soft })
hl("TroubleFileName", { fg = c.paper, bold = true })
hl("TroubleDirectory", { fg = c.oxide, bold = true })
hl("TroubleIconFile", { fg = c.steel })
hl("TroubleIconDirectory", { fg = c.oxide })
hl("TroubleCount", { fg = c.muted })
hl("TroubleIndent", { fg = c.border })
hl("TroubleSignError", { fg = c.alert })
hl("TroubleSignWarn", { fg = c.brass })
hl("TroubleSignInfo", { fg = c.steel })
hl("TroubleSignHint", { fg = c.oxide })
hl("TroublePreview", { bg = c.selection })

-- Which-key / misc ----------------------------------------------------------
hl("WhichKey", { fg = c.alert, bold = true })
hl("WhichKeyGroup", { fg = c.oxide })
hl("WhichKeyDesc", { fg = c.paper })
hl("WhichKeyFloat", { bg = c.surface })
hl("WhichKeyBorder", { fg = c.border, bg = c.surface })
hl("WhichKeySeparator", { fg = c.muted })
hl("SnacksNotifierInfo", { fg = c.steel })
hl("SnacksNotifierWarn", { fg = c.brass })
hl("SnacksNotifierError", { fg = c.alert })
hl("SnacksNotifierBorder", { fg = c.border, bg = c.surface })
