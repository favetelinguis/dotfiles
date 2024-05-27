;;; -*- lexical-binding: t; -*-
(load-theme 'modus-vivendi)
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
	version-control t      ; Use version numbers on backups
	delete-old-versions t  ; Automatically delete excess backups
	kept-new-versions 20   ; how many of the newest versions to keep
	kept-old-versions 5    ; and how many of the old
	)

  ;; Allow all disabled comands as default, for example a in dired
  (setq disabled-command-function nil)

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
  (tool-bar-mode -1)  (global-set-key (kbd "M-o") 'other-window)
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
(use-package dired
  :straight nil
  :config
  (setf dired-kill-when-opening-new-dired-buffer t))

(use-package ibuffer
  :straight nil
  :config
  (global-set-key (kbd "C-x C-b") 'ibuffer))

(use-package avy
  :bind (("M-g w" . avy-goto-word-1)))

(use-package corfu
  :config
  (global-corfu-mode)
  (setq corfu-auto t
	corfu-cycle t))

(use-package vertico
  :config
  (vertico-mode +1)
  (setq vertico-cycle t))

(use-package consult-project-extra
  :straight (consult-project-extra :type git :host github :repo "Qkessler/consult-project-extra")
  :config
  ;; TODO need new keys
  ;; (meow-leader-define-key
  ;;  '("j" . consult-project-extra-find)
  ;;  '("J" . consult-project-extra-find-other-window))
  )

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
  :config
  (project-remember-projects-under "~/repos" t))

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
(use-package smartparens
  :config
  (smartparens-global-mode t)) ; there is also smartparens-strict-mode

(use-package cider)
;; TODO need keybindings
(use-package clay
  :straight (:host github :repo "scicloj/clay.el"))
(use-package markdown-mode)

(use-package org
  :config
  (setq org-agenda-files '("todo.org"))

  (setq org-agenda-start-with-log-mode 't)
  (setq org-log-done 'note)
  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "~/org/todo.org" "Tasks")
           "* TODO %?\n  %i\n  %a"
           :prepen t))))
(use-package org-roam
  :config
  (org-roam-complete-everywhere)
  (org-roam-db-autosync-enable)
  ;; TODO need new keys
  ;; (meow-leader-define-key
  ;;  '("a" . org-agenda)
  ;;  '("n" . org-capture)
  ;;  '("e" . consult-flymake)
  ;;  '("N" . org-roam-capture)
  ;;  '("d" . org-roam-dailies-capture-today)
  ;;  '("D" . org-roam-dailies-capture-tomorrow))
  )

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

;; Smarter edit of embark-export for grep-buffers or x-ref buffers
(use-package wgrep)

(use-package embark
  :bind
  (("C-;" . embark-act)))

(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package popper
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          help-mode
          compilation-mode))
  (popper-mode +1)
  (popper-echo-mode +1))                ; For echo area hints

(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook
  (completion-list-mode . consult-preview-at-point-mode))
