;;; init.el -*- lexical-binding: t; -*-

(doom! :input
       :completion
       (vertico +icons)

       :ui
       doom
       dashboard
       hl-todo
       modeline
       nav-flash
       ophints
       (popup +defaults)
       treemacs
       vc-gutter
       vi-tilde-fringe
       window-select
       workspaces
       zen

       :editor
       (evil +everywhere)
       file-templates
       fold
       format
       multiple-cursors
       snippets

       :emacs
       dired
       electric
       ibuffer
       undo
       vc

       :term
       vterm

       :checkers
       syntax
       (spell +flyspell)

       :tools
       (eval +overlay)
       lookup
       lsp
       magit
       make
       tree-sitter

       :os
       macos
       tty

       :lang
       (cc +lsp)
       (go +lsp)
       (json +lsp)
       (javascript +lsp +tree-sitter)
       (lua +lsp)
       markdown
       (org +pretty +roam2)
       (rust +lsp)
       (sh +lsp)
       (web +lsp)
       (yaml +lsp)

       :config
       (default +bindings +smartparens))
