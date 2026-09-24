;;; config.el -*- lexical-binding: t; -*-

(setq user-full-name "jafari"
      doom-theme 'doom-gruvbox
      doom-font (font-spec :family "Hack Nerd Font Mono" :size 16)
      display-line-numbers-type 'relative
      org-directory "~/notes"
      org-roam-directory (file-truename "~/notes"))

(setq-default tab-width 4
              evil-shift-width 4)

(defun jafari/find-file-vsplit ()
  (interactive)
  (split-window-right)
  (other-window 1)
  (call-interactively #'find-file))

(defun jafari/find-file-split ()
  (interactive)
  (split-window-below)
  (other-window 1)
  (call-interactively #'find-file))

(defun jafari/lsp-definition-vsplit ()
  (interactive)
  (split-window-right)
  (other-window 1)
  (call-interactively #'xref-find-definitions))

(defun jafari/lsp-definition-split ()
  (interactive)
  (split-window-below)
  (other-window 1)
  (call-interactively #'xref-find-definitions))

(defun jafari/toggle-terminal ()
  (interactive)
  (if (fboundp '+vterm/toggle)
      (+vterm/toggle)
    (vterm)))

(defun jafari/open-directory-workspace ()
  (when-let ((directory (seq-find #'file-directory-p command-line-args)))
    (let ((default-directory (file-name-as-directory (expand-file-name directory))))
      (dired default-directory)
      (let ((dired-window (selected-window)))
        (treemacs-add-and-display-current-project-exclusively)
        (select-window dired-window)
        (+vterm/here t)))))

(add-hook 'emacs-startup-hook #'jafari/open-directory-workspace)

(defun jafari/project-switch ()
  (interactive)
  (call-interactively #'projectile-switch-project))

(defun jafari/diagnostics ()
  (interactive)
  (if (fboundp 'flycheck-list-errors)
      (flycheck-list-errors)
    (flymake-show-buffer-diagnostics)))

(defun jafari/next-diagnostic ()
  (interactive)
  (if (fboundp 'flycheck-next-error)
      (flycheck-next-error)
    (flymake-goto-next-error)))

(defun jafari/previous-diagnostic ()
  (interactive)
  (if (fboundp 'flycheck-previous-error)
      (flycheck-previous-error)
    (flymake-goto-prev-error)))

(defun jafari/search-notes ()
  (interactive)
  (consult-ripgrep org-directory))

(after! evil
  (map! :n "|" #'jafari/find-file-vsplit
        :n "_" #'jafari/find-file-split
        :n "gd" #'xref-find-definitions
        :n "gv" #'jafari/lsp-definition-vsplit
        :n "gh" #'jafari/lsp-definition-split
        :n "gr" #'xref-find-references
        :n "gi" #'+lookup/implementations
        :n "gt" #'+lookup/type-definition
        :n "K" #'+lookup/documentation
        :n "]d" #'jafari/next-diagnostic
        :n "[d" #'jafari/previous-diagnostic
        :n [C-left] #'evil-window-left
        :n [C-right] #'evil-window-right
        :n [C-up] #'evil-window-up
        :n [C-down] #'evil-window-down
        :n [C-S-z] #'evil-redo
        :v [tab] #'+evil/shift-right
        :v [backtab] #'+evil/shift-left
        :n [C-/] #'jafari/toggle-terminal
        :n [C-_] #'jafari/toggle-terminal))

(map! :leader
      :desc "File tree" "e" #'treemacs
      :desc "Scratch buffer" "." #'doom/open-scratch-buffer
      :desc "Zen mode" "z" #'writeroom-mode

      (:prefix ("f" . "find")
       :desc "Find file" "f" #'projectile-find-file
       :desc "Project search" "g" #'+default/search-project
       :desc "Search buffer" "b" #'consult-line)

      (:prefix ("d" . "diagnostics")
       :desc "File diagnostics" "f" #'jafari/diagnostics
       :desc "Workspace diagnostics" "w" #'jafari/diagnostics)

      (:prefix ("g" . "git")
       :desc "Magit status" "s" #'magit-status
       :desc "File history" "f" #'magit-log-buffer-file
       :desc "Line/file history" "l" #'magit-log-buffer-file
       :desc "Current hunk" "p" #'diff-hl-show-hunk
       :desc "File diff" "d" #'magit-diff-buffer-file
       :desc "Blame" "b" #'magit-blame-addition)

      (:prefix ("l" . "lsp")
       :desc "Diagnostics list" "d" #'jafari/diagnostics
       :desc "Document symbols" "s" #'consult-imenu
       :desc "Workspace symbols" "w" #'lsp-find-workspace-symbol
       :desc "Code action" "a" #'lsp-execute-code-action
       :desc "Rename" "n" #'lsp-rename
       :desc "Format buffer" "f" #'lsp-format-buffer
       :desc "Restart LSP" "R" #'lsp-workspace-restart)

      (:prefix ("n" . "notes")
       :desc "New/find note" "n" #'org-roam-node-find
       :desc "Daily note" "d" #'org-roam-dailies-goto-today
       :desc "Find note" "f" #'org-roam-node-find
       :desc "Search notes" "s" #'jafari/search-notes
       :desc "Backlinks" "b" #'org-roam-buffer-toggle
       :desc "Insert link" "l" #'org-roam-node-insert
       :desc "Capture note" "c" #'org-roam-capture
       :desc "Yesterday" "y" #'org-roam-dailies-goto-yesterday
       :desc "Tomorrow" "r" #'org-roam-dailies-goto-tomorrow)

      (:prefix ("p" . "project")
       :desc "Switch project" "l" #'jafari/project-switch
       :desc "Add project" "s" #'projectile-add-known-project
       :desc "Remove project" "d" #'projectile-remove-known-project)

      (:prefix ("w" . "window")
       :desc "Focus editor" "f" #'doom/window-enlargen
       :desc "Close split" "q" #'evil-window-delete
       :desc "Only this window" "o" #'delete-other-windows
       :desc "Equalize splits" "=" #'balance-windows
       :desc "Vertical split" "x" #'evil-window-vsplit
       :desc "Horizontal split" "s" #'evil-window-split
       :desc "Next buffer" "n" #'next-buffer
       :desc "Previous buffer" "p" #'previous-buffer
       :desc "Kill buffer" "c" #'kill-current-buffer
       :desc "Kill all other buffers" "A" #'doom/kill-other-buffers))

(after! org
  (setq org-hide-emphasis-markers t
        org-startup-indented t
        org-pretty-entities t))
