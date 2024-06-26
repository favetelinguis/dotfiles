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
  :custom
  ((global-subword-mode t)           ; aaBB will be treated as 2 words
   ;;   (global-superword-mode t)         ; aa-bb aa_bb aaBB all will be treated as 1 word, can not be anabled with subword-mode
   (column-number-mode t)
   (electric-pair-mode t))
  :bind
  (("M-i" . imenu))
  :config
  ;;; Prevent Extraneous Tabs
  (setq-default indent-tabs-mode nil)
  ;; Dont write custom data into init.el
  (setq custom-file (concat user-emacs-directory "custom.el"))
  
  (setq auto-save-default nil)

  ;; Handle backupfile outside projects directory
  (setq backup-directory-alist (list (cons "." (concat user-emacs-directory "backup")))
	backup-by-copying t    ; Don't delink hardlinks
        create-lockfiles nil
	version-control t      ; Use version numbers on backups
	delete-old-versions t  ; Automatically delete excess backups
	kept-new-versions 20   ; how many of the newest versions to keep
	kept-old-versions 5    ; and how many of the old
	)
  (global-visual-line-mode)
  (setq scroll-margin 0)
  (setq hscroll-margin 1)
  ;; Allow all disabled comands as default, for example a in dired
  (setq disabled-command-function nil)
  ;; Improve working with marks
  ;; https://github.com/VernonGrant/discovering-emacs/blob/main/show-notes/2-efficiency-with-the-mark-ring.md
  (setq mark-ring-max 6)
  (setq global-mark-ring-max 8)
  (setq-default set-mark-command-repeat-pop t)
  (setq project-vc-extra-root-markers '(".project"))
  (setq switch-to-buffer-obey-display-actions t)
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
  (define-key global-map (kbd "M-o") 'other-window)
  ;; Allows me to start jetbrains ides from inside emacs
  (when (executable-find "jetbrains-toolbox")
    (let ((path (concat (getenv "HOME") "/.local/share/JetBrains/Toolbox/scripts")))
      (setenv "PATH" (concat path ":" (getenv "PATH")))
      (setq exec-path (cons path exec-path)))))
(use-package which-key
  :config
  (which-key-mode))
(use-package autoinsert
  :straight nil
  :config
  (add-hook 'find-file-hook 'auto-insert))
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

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package tldr)
(use-package gptel
  :preface
  (defun my/read-openai-key ()
    (with-temp-buffer
      (insert-file-contents "~/.key.txt")
      (string-trim (buffer-string))))

  :bind (("C-c C-j" . gptel-send))
  :config
  (setq-default gptel-model "gpt-4o"
                gptel-default-mode 'org-mode
                gptel-api-key #'my/read-openai-key))

;; Setup languages in separate modules
(use-package myclojure
  :straight nil
  :init (require 'myclojure)
  :load-path "myelisp/")
;; (use-package mywindowconfigs
;;   :straight nil
;;   :init (require 'mywindowconfigs)
;;   :bind (("C-`" . window-toggle-side-windows))
;;   :load-path "myelisp/")

(use-package markdown-mode)

(use-package vterm
  :bind
  ((:map project-prefix-map ("s" . vterm))))

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

(use-package helpful
  :bind (("C-h f" . #'helpful-callable)
         ("C-h v" . #'helpful-variable)
         ("C-h k" . #'helpful-key)
         ("C-c C-d" . #'helpful-at-point) ; Maybe this should go in to elisp local map?
         ("C-h F" . #'helpful-function)))

(use-package elisp-demos
  :after helpful
  :config
  (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))

(use-package ibuffer
  :straight nil
  :config
  (define-key global-map [remap list-buffers] #'ibuffer))

(use-package pass)
;; Setup Scheme
(use-package geiser)
(use-package geiser-guile
  :after geiser)
(use-package just-mode)
(use-package dockerfile-mode)
;; Setup isearch other window
(defun isearch-forward-other-window (prefix)
  "Function to isearch-forward in other-window."
  (interactive "P")
  (unless (one-window-p)
    (save-excursion
      (let ((next (if prefix -1 1)))
        (other-window next)
        (isearch-forward)
        (other-window (- next))))))

(defun isearch-backward-other-window (prefix)
  "Function to isearch-backward in other-window."
  (interactive "P")
  (unless (one-window-p)
    (save-excursion
      (let ((next (if prefix 1 -1)))
        (other-window next)
        (isearch-backward)
        (other-window (- next))))))

(define-key global-map (kbd "C-M-s") 'isearch-forward-other-window)
(define-key global-map (kbd "C-M-r") 'isearch-backward-other-window)

;; I think this should add support for color in compilation buffers need testing to confirm
;; maybe i want https://codeberg.org/ideasman42/emacs-fancy-compilation
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(use-package justl
  :config
  (setq justl-per-recipe-buffer t)
  :bind
  (:map project-prefix-map ("j" . justl)))

