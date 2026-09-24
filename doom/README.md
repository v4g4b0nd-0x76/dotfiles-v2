# Doom Emacs

Small Doom setup for macOS and Linux, with your Neovim muscle memory carried over where Doom already has the feature.

## Best Version

Use a stable Emacs, not a pre-release. As of the checked official docs/history on 2026-09-21:

- Doom currently recommends GNU Emacs 31.1.
- GNU lists Emacs 30.2 as the latest stable release history entry I found.

So the lazy answer is: install the newest stable Emacs your package manager gives you, preferably 30.2+ now, then let Doom's `doom doctor` complain if your machine is missing anything.

## Install

macOS with Homebrew:

```sh
brew install git ripgrep fd coreutils
brew tap railwaycat/emacsmacport
brew install emacs-mac --with-modules
git clone --depth 1 https://github.com/doomemacs/core ~/.config/emacs
ln -sfn ~/dotfiles/doom ~/.config/doom
~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom sync
```

Linux:

```sh
sudo apt install emacs git ripgrep fd-find
git clone --depth 1 https://github.com/doomemacs/core ~/.config/emacs
ln -sfn ~/dotfiles/doom ~/.config/doom
~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom sync
```

If this repo lives somewhere else, change `~/dotfiles/doom` to this directory.

## Carried Over Keys

- `SPC e`: file tree
- `SPC .`: scratch buffer
- `SPC z`: Zen mode
- `SPC f f`: find file
- `SPC f g`: project search
- `SPC f b`: search current buffer
- `SPC d f`, `SPC d w`: diagnostics
- `SPC g s`: Magit status
- `SPC g f`: file history
- `SPC g d`: current file diff
- `SPC g p`: preview hunk
- `SPC l a/n/f/R`: code action, rename, format, restart LSP
- `SPC n n/d/f/s/b/l/c`: notes with Org-roam
- `SPC p l/s/d`: project switch/add/remove
- `SPC w x/s/q/o/=/n/p/c/A`: split and buffer workflow
- `|`, `_`: find file in vertical/horizontal split
- `gd`, `gv`, `gh`, `gr`, `gi`, `gt`, `K`: LSP lookup flow
- `[d`, `]d`: previous/next diagnostic
- `Ctrl` + arrows: move between splits
- `Ctrl-/` or `Ctrl-_`: toggle terminal

Skipped a full Neovim plugin clone. Doom already has Magit, LSP, Vertico, Treemacs, Org-roam, vterm, and workspaces; add custom packages only when one of those actually falls short.
