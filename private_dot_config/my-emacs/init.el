;;; -*- lexical-binding: t; -*-
(load-theme 'modus-operandi)
;; This needs to be set before use-package is loaded
(setq use-package-enable-imenu-support t)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(setq straight-use-package-by-default t)

;; Setup font START
(defvar using-sharing-font nil)

(defun set-standard-font ()
  (set-face-attribute 'default nil :font "Fira Code-12"))

(defun set-sharing-font ()
  (set-face-attribute 'default nil :font "Fira Code-16"))

(defun switch-font ()
  "Switches the font between my normal one and the one used to share screen"
  (interactive)
  (if using-sharing-font
      (set-standard-font)
    (set-sharing-font))
  (setq using-sharing-font (not using-sharing-font)))
(set-standard-font)

(use-package emacs
  :config
  ;;; Prevent Extraneous Tabs
  (setq-default indent-tabs-mode nil)
  ;; Dont write custom data into init.el
  (setq custom-file (concat user-emacs-directory "custom.el"))
  
  (setq auto-save-default nil)

  ;; Turn on relative line numbers
  ;;(global-display-line-numbers-mode 1)
  ;;(setq display-line-numbers-type 'relative)

  ;; Handle backupfile outside projects directory
  (setq backup-directory-alist (list (cons "." (concat user-emacs-directory "backup")))
	backup-by-copying t    ; Don't delink hardlinks
        create-lockfiles nil
	version-control t      ; Use version numbers on backups
	delete-old-versions t  ; Automatically delete excess backups
	kept-new-versions 20   ; how many of the newest versions to keep
	kept-old-versions 5    ; and how many of the old
	)

  ;; Allow all disabled comands as default, for example a in dired
  (setq disabled-command-function nil)
  (electric-pair-mode 1)
  ;; Improve working with marks
  ;; https://github.com/VernonGrant/discovering-emacs/blob/main/show-notes/2-efficiency-with-the-mark-ring.md
  (setq mark-ring-max 6)
  (setq global-mark-ring-max 8)
  (setq-default set-mark-command-repeat-pop t)


  ;; Cleanup Emacs user interface
  (setq inhibit-startup-message t)
  (scroll-bar-mode -1) ; Disable visible scrollbar
  (tool-bar-mode -1)  ; Disable the toolbar
  (tooltip-mode -1) ; Disable tooltips
  (set-fringe-mode 10)
  (menu-bar-mode -1) ; Disable the menu bar
  (setq visible-bell t) ; Turn off sound and show flashing warning instead
  (menu-bar-mode -1)
  (scroll-bar-mode -1)
  (tool-bar-mode -1)  
  (blink-cursor-mode 0)
  (setq use-short-answers t)
  (setq help-window-select t)
  ;; Emacs 28 and newer: Hide commands in M-x which do not work in the current
  ;; mode.  Vertico commands are hidden in normal buffers. This setting is
  ;; useful beyond Vertico.
  (setq read-extended-command-predicate #'command-completion-default-include-p)

  ;; Allows me to start jetbrains ides from inside emacs
  (when (executable-find "jetbrains-toolbox")
    (let ((path (concat (getenv "HOME") "/.local/share/JetBrains/Toolbox/scripts")))
      (setenv "PATH" (concat path ":" (getenv "PATH")))
      (setq exec-path (cons path exec-path)))))
(use-package which-key
  :config
  (which-key-mode))

(use-package corfu
  :config
  (global-corfu-mode)
  (setq corfu-auto t
	corfu-cycle t))

(use-package vertico
  :config
  (vertico-mode +1)
  (setq vertico-cycle t))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

(use-package orderless
  :config
  (setq completion-styles '(orderless)))

(use-package marginalia
  :config
  (marginalia-mode))

(use-package project
  :straight nil
  :preface
  (defun my/project-refresh ()
    (interactive)
    (project-remember-projects-under "~/repos" t)))

(use-package chezmoi)
(use-package chezmoi-dired
  :after chezmoi
  :straight nil
  :load-path "straight/repos/chezmoi.el/extensions/")

(use-package apheleia
  :config
  (apheleia-global-mode +1))

(use-package asdf
  :straight (:host github :repo "tabfugnic/asdf.el")
  :init
  (setq asdf-binary "/opt/asdf-vm/bin/asdf")
  :config
  (asdf-enable))

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package tldr)
(use-package gptel
  :preface
  (defun my/read-openai-key ()
    (with-temp-buffer
      (insert-file-contents "~/key.txt")
      (string-trim (buffer-string))))

  :config
  (setq-default gptel-model "gpt-3.5-turbo"
                gptel-playback t
                gptel-default-mode 'markdown-mode
                gptel-api-key #'my/read-openai-key))

(use-package clojure-mode)

(use-package cider)
;; TODO need keybindings
(use-package clay
  :straight (:host github :repo "scicloj/clay.el"))
(use-package markdown-mode)



(use-package git-timemachine)

(use-package ibuffer-vc
  :config
  ;; Always group by VC
  (add-hook 'ibuffer-hook
            (lambda ()
              (ibuffer-vc-set-filter-groups-by-vc-root)
              (unless (eq ibuffer-sorting-mode 'alphabetic)
                (ibuffer-do-sort-by-alphabetic))))
  ;; Include VC status
  (setq ibuffer-formats
        '((mark modified read-only vc-status-mini " "
                (name 18 18 :left :elide)
                " "
                (size 9 -1 :right)
                " "
                (mode 16 16 :left :elide)
                " "
                (vc-status 16 16 :left)
                " "
                vc-relative-file))))
(use-package project-mode-line-tag
  :config
  (project-mode-line-tag-mode 1))

;; Smarter edit of for grep-buffers or x-ref buffers
(use-package wgrep)

(use-package nov
  :ensure t
  :mode ("\\.epub\\'" . nov-mode))

(use-package avy)

(use-package meow
  :preface
  (defun meow-setup ()
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    (meow-normal-define-key
     '("-" . negative-argument)
     '(";" . meow-reverse)
     '("a" . meow-append)
     '("A" . meow-open-below)
     '("b" . meow-back-word)
     '("B" . meow-back-symbol)
     '("c" . meow-change)
     '("d" . meow-delete)
     '("C" . meow-comment)
     '("D" . meow-backward-delete)
     '("e" . meow-next-word)
     '("E" . meow-next-symbol)
     '("T" . meow-inner-of-thing)
     '("t" . meow-bounds-of-thing)
     '("g" . meow-cancel-selection)
     '("G" . meow-grab)
     '("h" . meow-left)
     '("H" . meow-left-expand)
     '("i" . meow-insert)
     '("I" . meow-open-above)
     '("n" . meow-next)
     '("N" . meow-next-expand)
     '("p" . meow-prev)
     '("P" . meow-prev-expand)
     '("l" . meow-right)
     '("L" . meow-right-expand)
     '("m" . meow-join)
     '("j" . avy-goto-word-1)
     '("J" . meow-search)
     '("o" . meow-block)
     '("O" . meow-to-block)
     '("s" . meow-yank)
     '("S" . meow-clipboard-yank)
     '("q" . meow-quit)
     '("Q" . meow-goto-line)
     '("r" . meow-replace)
     '("R" . meow-swap-grab)
     '("F" . meow-beginning-of-thing)
     '("f" . meow-end-of-thing)
     '("k" . meow-kill)
     '("u" . meow-undo)
     '("U" . meow-undo-in-selection)
     '("w" . meow-mark-word)
     '("W" . meow-mark-symbol)
     '("x" . meow-line)
     '("X" . meow-goto-line)
     '("y" . meow-save)
     '("Y" . meow-clipboard-save)
     ;; '("Y" . meow-sync-grab) ; TODO where should i put this
     '("z" . meow-pop-selection)
     '("'" . repeat)
     '("SPC" . meow-paren-mode)
     '("<escape>" . ignore)))
  :config
  (setq meow-expand-hint-remove-delay 0) ; dissable index hints
  (setq meow-cheatsheet-physical-layout meow-cheatsheet-physical-layout-ansi)
  (meow-setup)
  (meow-global-mode 1)
  (meow-setup-indicator))

(use-package puni
  :defer t
  ;; :bind (())
  :init
  ;; The autoloads of Puni are set up so you can enable `puni-mode` or
  ;; `puni-global-mode` before `puni` is actually loaded. Only after you press
  ;; any key that calls Puni commands, it's loaded.
  (puni-global-mode)
  (add-hook 'term-mode-hook #'puni-disable-puni-mode)

  (setq meow-paren-keymap (make-keymap))
  (meow-define-state paren
    "meow state for interacting with smartparens"
    :lighter " [P]"
    :keymap meow-paren-keymap)

  ;; meow-define-state creates the variable
  (setq meow-cursor-type-paren 'hollow)

  (meow-define-keys 'paren
    '("<escape>" . meow-normal-mode)
    '("SPC" . meow-insert)
    '("n" . puni-syntactic-forward-punct)
    '("p" . puni-syntactic-backward-punct)
    '("l" . puni-forward-sexp)
    '("h" . puni-backward-sexp)
    '("a" . puni-beginning-of-sexp)
    '("e" . puni-end-of-sexp)
    '("r" . puni-raise)
    '("s" . puni-slurp-forward)
    '("S" . puni-slurp-backward)
    '("b" . puni-barf-forward)
    '("B" . puni-barf-backward)
    '("d" . puni-splice)
    '("t" . puni-transpose)
    '("c" . puni-convolute)
    '("(" . puni-wrap-round)
    '("[" . puni-wrap-square)
    '("{" . puni-wrap-curly)
    '("<" . puni-wrap-angle)
    '("u" . meow-undo)))

(use-package org
  :straight nil
  :bind (("C-c C-n n" . org-capture)
         ("C-c C-n a" . org-agenda))
  :config
  (setq org-agenda-files '("~/org"))
  (setq org-agenda-start-with-log-mode 't)
  (setq org-log-done 'note)
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "~/org/todo.org" "Tasks")
           "* TODO %?\n  %i\n  %a"
           :prepen t))))

(use-package denote
  :after org
  :config
  (setq denote-directory (expand-file-name "~/org"))
  (setq denote-known-keywords '("konowledge" "meeting"))
  (add-to-list 'org-capture-templates
               '("n" "New note (with Denote)" plain
                 (file denote-last-path)
                 #'denote-org-capture
                 :no-save t
                 :immediate-finish nil
                 :kill-buffer t
                 :jump-to-captured t)))
(use-package dired-hide-dotfiles
  :hook
  (dired-mode . dired-hide-dotfiles-mode)
  :bind
  (:map dired-mode-map ("." . dired-hide-dotfiles-mode)))

