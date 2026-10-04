# Neovim YoRHa Ronin Command Deck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a quiet NieR-inspired daily Neovim HUD and an on-demand full-screen samurai-occult command deck using the repository's existing plugins.

**Architecture:** A single `_G.YorhaRonin` table in `nvim/init.lua` owns display-safe HUD and telemetry helpers required by statusline expressions and tests. Lualine and the native winbar render the daily state; the existing Snacks dashboard renders the full-screen deck from declarative multi-pane sections and existing Telescope, Trouble, project, terminal, scratch, Diffview, and session actions.

**Tech Stack:** Lua, Neovim APIs, lazy.nvim, Snacks dashboard, Lualine, existing Telescope/Trouble/Gitsigns/TODO Comments integrations, POSIX shell test runner

**Spec:** `docs/superpowers/specs/2026-10-04-nvim-yorha-ronin-command-deck-design.md`

## Global Constraints

- Preserve Srcery as the code colorscheme and do not broadly remap syntax highlights.
- Modify Neovim only; do not touch Doom, Ghostty, Kitty, Alacritty, tmux, shell, icons, or desktop configuration.
- Add no plugin or external runtime dependency.
- Keep `nvim/init.lua` as the structured main configuration file.
- Support macOS and Linux; optional Git and ripgrep data must disappear cleanly when unavailable.
- Do not run permanent polling loops; refresh deck telemetry when the deck opens.
- Preserve every existing mapping and workflow not explicitly replaced by the approved dashboard.
- Treat rendered screenshots, not headless checks alone, as visual acceptance evidence.

## Review Focus

- Unnamed, special, and help buffers must render the HUD without errors or misleading paths; Task 1 exercises unnamed, `nofile`, and help buffers.
- Colorscheme reloads must restore the custom HUD/deck highlight groups; Task 1 clears and reapplies one group through `ColorScheme`.
- A narrow terminal must open and close the deck without clipped required actions or Lua errors; Task 2 opens it at 80 columns.
- Non-Git directories and missing `git`/`rg` executables must yield empty or muted values without notifications; Task 3 tests a temporary directory with an empty `PATH`.
- A missing `.nvim_session` must disable resume while a present session enables it; Task 3 tests both states in an isolated temporary directory.

---

### Task 1: Daily HUD and Visual Primitives

**Files:**
- Modify: `nvim/init.lua:102-118`
- Modify: `nvim/init.lua:554-636`
- Create: `nvim/tests/test-yorha-ronin.lua`
- Modify: `nvim/tests/test-ui.sh:5-12`

**Interfaces:**
- Consumes: Srcery highlights, `vim.diagnostic`, `vim.lsp`, `vim.uv` or `vim.loop`, and Lualine's existing Git components.
- Produces: `_G.YorhaRonin.project_name(cwd?) -> string`, `_G.YorhaRonin.relative_file(bufnr?) -> string`, `_G.YorhaRonin.lsp_name(bufnr?) -> string`, `_G.YorhaRonin.diagnostics(bufnr?) -> string`, `_G.YorhaRonin.session_elapsed() -> string`, `_G.YorhaRonin.winbar() -> string`, and `_G.YorhaRonin.apply_highlights() -> nil`.

- [ ] **Step 1: Add the failing HUD assertions**

Remove the stale `|___|` dashboard-header assertion from `nvim/tests/test-ui.sh`; the current checked-in artwork no longer contains that marker, so the baseline script already exits 1 before exercising new behavior. Task 2 replaces it with an assertion for the new approved header.

Create `nvim/tests/test-yorha-ronin.lua` with assertions that:

```lua
assert(type(YorhaRonin) == "table", "YorhaRonin HUD must be defined")
assert(vim.o.winbar == "%{%v:lua.YorhaRonin.winbar()%}")

vim.cmd("enew!")
assert(YorhaRonin.relative_file() == "[No Name]")
assert(YorhaRonin.lsp_name() == "")
assert(YorhaRonin.diagnostics() == "")
assert(YorhaRonin.winbar():find("[No Name]", 1, true))
assert(YorhaRonin.session_elapsed():match("^%d%d:%d%d$") ~= nil)

vim.bo.buftype = "nofile"
assert(pcall(YorhaRonin.winbar))
vim.cmd("help help")
assert(pcall(YorhaRonin.winbar))
vim.cmd("bdelete!")

local signal = vim.api.nvim_get_hl(0, { name = "YorhaSignal", link = false })
assert(signal.fg == 0xf75341)
vim.api.nvim_set_hl(0, "YorhaSignal", {})
vim.api.nvim_exec_autocmds("ColorScheme", {})
assert(vim.api.nvim_get_hl(0, { name = "YorhaSignal", link = false }).fg == 0xf75341)

local lualine = require("lualine").get_config()
assert(lualine.options.globalstatus == true)
assert(lualine.options.section_separators.left == "")
```

Source this file from `nvim/tests/test-ui.sh` after its existing plugin/color assertions.

- [ ] **Step 2: Run the UI test and verify the new test fails**

Run: `sh nvim/tests/test-ui.sh`

Expected: FAIL with `YorhaRonin HUD must be defined`.

- [ ] **Step 3: Implement the HUD interfaces and highlights**

In sections 2-3 of `nvim/init.lua`, replace `_G.SimpleWinbar` with `_G.YorhaRonin` and the exact interfaces above. Use `#f75341` for signal red, `#fce8c3` for paper, `#917e6b` for muted text, `#fbb829` for brass, `#519f50` for healthy state, and `#121110` for the base surface. Register one `ColorScheme` autocmd that calls `YorhaRonin.apply_highlights()`.

In the Lualine spec, use a flat custom theme and configure these sections:

- `a`: mode with the blade mark `刀`;
- `b`: existing branch and diff components;
- `c`: relative filename and modified/readonly state;
- `x`: attached LSP and filetype, omitting empty LSP output;
- `y`: diagnostics, omitting zero counts;
- `z`: session elapsed time and location.

- [ ] **Step 4: Run focused tests**

Run: `sh nvim/tests/test-ui.sh`

Expected: PASS, including unnamed and `nofile` HUD assertions.

- [ ] **Step 5: Commit the daily HUD**

```bash
git add nvim/init.lua nvim/tests/test-ui.sh nvim/tests/test-yorha-ronin.lua
git commit -m "feat(nvim): add yorha ronin daily hud"
```

### Task 2: Full-Screen Command Deck and Actions

**Files:**
- Modify: `nvim/init.lua:663-752`
- Modify: `nvim/tests/test-yorha-ronin.lua`
- Modify: `nvim/tests/test-ui.sh:5-13`

**Interfaces:**
- Consumes: `_G.YorhaRonin` from Task 1 and existing mappings/commands for Telescope, Trouble, TODO Comments, Diffview, project selection, Snacks terminal, and Snacks scratch.
- Produces: `_G.YorhaRonin.deck_sections() -> snacks.dashboard.Section`, `_G.YorhaRonin.open_deck() -> nil`, the `<leader>ud` mapping, and a shared Snacks dashboard configuration used at startup and on demand.

- [ ] **Step 1: Add failing deck configuration and lifecycle assertions**

Append assertions to `nvim/tests/test-yorha-ronin.lua` that:

```lua
local dashboard = Snacks.config.get("dashboard")
assert(type(YorhaRonin.deck_sections) == "function")
assert(type(dashboard.sections) == "table")
assert(dashboard.preset.header:find("YORHA // RONIN", 1, true))
assert(dashboard.preset.header:find("浪人", 1, true))
assert(vim.fn.maparg("<leader>ud", "n") ~= "")

local previous_columns = vim.o.columns
vim.o.columns = 80
local previous_tabs = vim.fn.tabpagenr("$")
assert(pcall(YorhaRonin.open_deck))
assert(vim.bo.filetype == "snacks_dashboard")
assert(vim.fn.tabpagenr("$") == previous_tabs + 1)
assert(vim.fn.maparg("q", "n", false, true).buffer == 1)
vim.cmd("bdelete!")
vim.o.columns = previous_columns
```

Add a `nvim/tests/test-ui.sh` assertion that the configured header contains `YORHA // RONIN`.

- [ ] **Step 2: Run the UI test and verify the deck test fails**

Run: `sh nvim/tests/test-ui.sh`

Expected: FAIL because `YorhaRonin.deck_sections` is missing or the new header is absent.

- [ ] **Step 3: Implement the shared multi-pane dashboard**

Replace the current oversized dashboard header with compact terminal-safe samurai art containing `YORHA // RONIN` and `浪人`. Configure `width = 42`, `pane_gap = 3`, and declarative sections across panes 1-3:

- pane 1: art/header, current campaign label, find files, live grep, symbols, scratch, and terminal;
- pane 2: recent files, Git/Diffview, Trouble diagnostics, and TODO search;
- pane 3: saved-project selection through `<leader>pl`, session resume, startup time, and quit/close actions.

Implement `YorhaRonin.open_deck()` by opening a new tab and calling `Snacks.dashboard.open({ buf = 0, win = 0 })`; `q`/Escape must close the dashboard buffer and return to the prior tab. Add `<leader>ud` with description `Toggle YoRHa Ronin command deck`. Reuse existing picker and command entry points; do not duplicate their behavior.

Register `<leader>u` as the `UI` group in the existing WhichKey configuration.

- [ ] **Step 4: Run the UI test at normal and narrow widths**

Run: `sh nvim/tests/test-ui.sh`

Expected: PASS; the deck opens as `snacks_dashboard`, owns a buffer-local `q`, and closes without an error at 80 columns.

- [ ] **Step 5: Commit the command deck shell**

```bash
git add nvim/init.lua nvim/tests/test-ui.sh nvim/tests/test-yorha-ronin.lua
git commit -m "feat(nvim): add yorha ronin command deck"
```

### Task 3: Live Telemetry, Fallbacks, and Visual Acceptance

**Files:**
- Modify: `nvim/init.lua:663-752`
- Modify: `nvim/tests/test-yorha-ronin.lua`
- Modify: `nvim/tests/test-ui.sh`
- Synchronize after acceptance: `/home/jafari/.config/nvim/init.lua`

**Interfaces:**
- Consumes: Task 1 HUD helpers and Task 2 dashboard sections.
- Produces: `_G.YorhaRonin.git_summary(cwd?) -> string`, `_G.YorhaRonin.todo_count(cwd?) -> string`, `_G.YorhaRonin.todo_status() -> string`, `_G.YorhaRonin.refresh_telemetry(cwd?) -> nil`, `_G.YorhaRonin.session_available(cwd?) -> boolean`, and `_G.YorhaRonin.telemetry_items() -> snacks.dashboard.Item[]`; the command deck resolves fresh items each time it opens while Lualine reads the cached TODO status.

- [ ] **Step 1: Add failing telemetry and fallback assertions**

Append a temporary-directory test to `nvim/tests/test-yorha-ronin.lua`:

```lua
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
local old_path = vim.env.PATH
local old_notify = vim.notify
local notifications = 0
vim.notify = function() notifications = notifications + 1 end
vim.env.PATH = ""
assert(YorhaRonin.git_summary(tmp) == "")
assert(YorhaRonin.todo_count(tmp) == "")
YorhaRonin.refresh_telemetry(tmp)
assert(YorhaRonin.todo_status() == "")
assert(YorhaRonin.session_available(tmp) == false)
vim.fn.writefile({ "let g:yorha_session_test = 1" }, tmp .. "/.nvim_session")
assert(YorhaRonin.session_available(tmp) == true)
assert(type(YorhaRonin.telemetry_items()) == "table")
assert(notifications == 0)
vim.env.PATH = old_path
vim.notify = old_notify
vim.fn.delete(tmp, "rf")
```

Also create one error and one warning diagnostic in a scratch buffer and assert `YorhaRonin.diagnostics()` returns `E:1 W:1`, then reset the diagnostic namespace.

- [ ] **Step 2: Run the UI test and verify telemetry interfaces are missing**

Run: `sh nvim/tests/test-ui.sh`

Expected: FAIL because `YorhaRonin.git_summary`, `todo_count`, `session_available`, or `telemetry_items` is undefined.

- [ ] **Step 3: Implement refresh-on-open telemetry**

Implement the six exact interfaces above. `git_summary` and `todo_count` must check `vim.fn.executable()` before using bounded `vim.system(...):wait()` calls; silence stderr and return `""` on absence, timeout, non-zero exit, or malformed output. `session_available` checks `<cwd>/.nvim_session`. `telemetry_items` returns muted dashboard items for project/branch, Git posture, diagnostics, TODOs, LSP, session availability, and session time, omitting optional values that are empty.

`refresh_telemetry` updates an in-memory TODO display cache. Call it when the deck opens and from one `BufWritePost` autocmd; add `todo_status` to Lualine's `y` section after diagnostics so the count appears only when non-zero. Insert `YorhaRonin.telemetry_items` as a function section so Snacks resolves fresh values on every dashboard open. Do not create timers or polling autocmds.

- [ ] **Step 4: Run all static and headless verification**

Run:

```bash
sh nvim/tests/test-ui.sh
XDG_STATE_HOME=/tmp/dotfiles-nvim-state XDG_CACHE_HOME=/tmp/dotfiles-nvim-cache nvim --headless -u nvim/init.lua '+luafile nvim/tests/test-srcery.lua' '+qa!'
git diff --check
```

Expected: all commands exit 0; Srcery remains active with opaque `#121110` normal background.

- [ ] **Step 5: Render and compare both UI states**

Open Neovim in a representative terminal of at least 120 columns. Capture:

1. a normal Rust/Lua editing buffer showing the daily HUD;
2. the `<leader>ud` command deck.

Compare both captures with the approved companion for hierarchy, spacing, thin borders, restrained signal red, readable art, and code-first visual weight. Iterate only the dashboard/HUD highlight and spacing values until both states match the accepted direction; rerun Step 4 after every edit.

- [ ] **Step 6: Synchronize and validate the active Neovim config**

Run:

```bash
cp nvim/init.lua /home/jafari/.config/nvim/init.lua
cmp -s nvim/init.lua /home/jafari/.config/nvim/init.lua
XDG_STATE_HOME=/tmp/dotfiles-nvim-live-state XDG_CACHE_HOME=/tmp/dotfiles-nvim-live-cache nvim --headless -u /home/jafari/.config/nvim/init.lua '+qa!'
```

Expected: `cmp` and the live-config headless load exit 0.

- [ ] **Step 7: Commit the telemetry and accepted polish**

```bash
git add nvim/init.lua nvim/tests/test-ui.sh nvim/tests/test-yorha-ronin.lua
git commit -m "feat(nvim): add live command deck telemetry"
```
