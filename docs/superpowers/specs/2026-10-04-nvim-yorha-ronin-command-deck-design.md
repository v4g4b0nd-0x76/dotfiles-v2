# Neovim YoRHa Ronin Command Deck Design

Date: 2026-10-04

## Objective

Turn the existing Neovim configuration into a two-state working environment:

1. A quiet daily editor with a restrained NieR-inspired HUD.
2. An on-demand command deck that exposes project, Git, diagnostic, task, recent-file, and session information through a samurai-occult interface.

The result must remain useful before decorative. It must preserve the current Srcery code palette, existing keymaps, current project workflow, and cross-platform behavior on macOS and Linux. Doom Emacs is out of scope.

## Approved Visual Direction

The approved prototype is the “YoRHa Ronin” two-state design:

- near-black surfaces, warm paper text, muted brass, moss, and limited signal red;
- thin rules, numbered labels, restrained typography, tactical telemetry, and NieR-like information hierarchy;
- samurai and occult motifs used as dashboard art, seals, and low-contrast marks rather than repeated decoration over code;
- a clean editor during normal work and a denser full-screen interface only when explicitly summoned.

Srcery remains the code colorscheme. New highlight groups may style the dashboard, Lualine, winbar, and related UI chrome, but must not replace or broadly remap syntax colors.

## Technical Approach

Reuse the capabilities already installed in the repository:

- `folke/snacks.nvim` supplies the startup dashboard, multiple panes, terminal-backed sections, and the command-deck buffer.
- `nvim-lualine/lualine.nvim` supplies the persistent bottom HUD.
- Neovim's native `winbar`, diagnostics API, timers, and filesystem functions supply lightweight live context.
- Existing Telescope, Trouble, Gitsigns, TODO Comments, terminal, project, and `.nvim_session` flows remain the actions behind command-deck entries.

No new plugin or external runtime dependency will be added. Optional data sources such as Git and ripgrep must degrade gracefully when unavailable.

## Daily HUD

The normal editing surface remains code-first. It contains:

- a thin winbar showing the current project or working-directory name, relative file path, attached LSP name, and modified state;
- a flat Lualine styled with the approved palette;
- mode and a small blade/seal mark on the left;
- Git branch and diff summary;
- file name and type;
- diagnostics and TODO count only when non-zero;
- session elapsed time and cursor position on the right.

No persistent sidebar opens automatically. The visual weight stays low: paper and muted colors carry ordinary state, brass marks caution, moss marks healthy state, and red is reserved for the active mode, errors, or required attention.

HUD components return an empty string when their information is unavailable. They must never raise an error during startup, on unnamed buffers, or outside a Git repository.

## Command Deck

`<leader>ud` toggles a full-screen Snacks dashboard called the command deck. The same deck replaces the current oversized startup header when Neovim starts without a file.

The wide layout uses three conceptual columns:

1. **Campaign:** compact samurai art, current project, branch, working directory, and primary actions.
2. **Telemetry:** Git posture, diagnostics, TODO count, LSP state, and recent targets.
3. **Objectives:** saved projects, session state, actionable tasks, and command shortcuts.

The layout collapses naturally on narrow terminals through Snacks' pane behavior rather than maintaining a separate UI implementation.

The first implementation includes these actions:

- resume `.nvim_session` when it exists;
- open recent files;
- find files, live grep, and symbols through Telescope;
- select an existing saved project using the current `projects.json` workflow;
- open Trouble diagnostics;
- search TODO comments;
- toggle the existing Snacks terminal and scratch buffer;
- open Git status/diff surfaces already provided by Telescope, Gitsigns, and Diffview;
- close the deck and return to the previous editing buffer.

The deck refreshes when opened. It does not run a permanent polling loop.

## Data and Rendering

Small local helpers in `nvim/init.lua` will expose display-safe strings for:

- project name and path;
- Git branch and changed-file summary;
- diagnostic counts;
- attached LSP clients;
- TODO count;
- session elapsed time;
- session-file availability.

Helpers use Neovim APIs first. Git and TODO summaries may use short bounded commands through `vim.system` where the installed plugins do not expose a stable public value. Command failures, non-Git directories, missing executables, and empty results produce a muted unavailable state or omit the item.

Decorative art is stored as Lua string data beside the dashboard configuration. It must fit comfortably at common terminal widths, avoid very wide Unicode glyphs that render inconsistently, and never cover working buffers.

## Configuration Placement

The repository's Neovim convention keeps configuration in the structured `nvim/init.lua` file. The implementation will therefore:

- add HUD helpers beside the existing Lualine configuration;
- replace the current Snacks dashboard preset with the command-deck sections;
- place deck actions and small data helpers near that Snacks specification;
- add global deck-related keymaps in the existing keymap section if they are not owned directly by the Snacks plugin spec;
- extend existing tests rather than introduce a second configuration structure.

If the deck cannot remain understandable as one bounded section, that is a reason to simplify its widgets, not to create a new framework.

## Failure Behavior

- Outside Git: omit branch/diff values and show the project path normally.
- Without ripgrep: hide the TODO total; existing TODO picker behavior remains unchanged.
- Without a session file: show “no field record” and disable the resume action.
- Without an attached LSP: omit its label.
- On a narrow terminal: collapse to fewer dashboard panes without clipping essential actions.
- On terminal-command failure: render a muted unavailable value; do not notify repeatedly or block startup.
- On an unnamed or special buffer: winbar and HUD helpers return safe fallback text.

## Verification

Automated checks will extend `nvim/tests/test-ui.sh` and related Lua assertions to cover:

- Srcery remains the active colorscheme;
- the command deck is enabled and has multiple panes/sections;
- `<leader>ud` is registered;
- Lualine and winbar components load on normal, unnamed, and non-Git buffers;
- optional widget helpers fail quietly when their source is absent;
- existing dashboard, terminal, scratchpad, Zen, project, and session mappings remain intact.

The finished configuration must also pass:

- a Lua parse or equivalent isolated Neovim headless load;
- the repository's Neovim UI test script;
- `git diff --check`.

Because this is a visual change, automated tests are not acceptance evidence by themselves. Final verification includes rendered screenshots of both the daily HUD and the full command deck at a representative terminal size, compared against the approved prototype for hierarchy, spacing, borders, palette, and visual weight.

## Non-Goals

- changing Doom Emacs;
- changing Ghostty, Kitty, Alacritty, tmux, shell, icons, or desktop configuration;
- replacing Srcery syntax colors;
- installing a new dashboard, session, or widget plugin;
- continuously polling Git, system resources, or background processes;
- adding decorative animation or sound in this iteration.
