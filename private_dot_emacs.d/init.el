;;; -*- lexical-binding: t; -*-

;; This file is organized by outlining using ;;; and ;;;; etc to represent levels,
;; then a command such as consult-outline bound to M-s M-s can be used to navigate.

;; Run M-x customize-variable RET my-enabled-packages RET
(defcustom my-enabled-packages '(clojure)
  "List of additional packages to conditionally load."
  :type '(set :tag "Enabled Packages"
              (const :tag "Lang - Zig" zig)
	      (const :tag "Lang - Clojure" clojure)
              (const :tag "Lang - Odin" odin)
	      (const :tag "Lang - Go" go)
	      (const :tag "Lang - Roc" roc)
              (const :tag "Lang - Janet" janet)
	      (const :tag "Infrastructure - K8" k8)
	      (const :tag "Infrastructure - Docker" docker)
	      )
  :group 'my-config)
(defun my-package-enabled-p (package)
  "Return non-nil if PACKAGE is in `my-enabled-packages'."
  (memq package my-enabled-packages))

;;; Bootstrap
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
;; and `package-pinned-packages`. Most users will not need or want to do this.
;;(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
;; for the compilation buffer to support colors
(use-package ansi-color
  :hook (compilation-filter . ansi-color-compilation-filter))

;; for compilation will remove the osc stuff making odin test better
(use-package ansi-osc
  :ensure t
  :hook (compilation-filter . ansi-osc-compilation-filter))




;; OBS will need to run kdl-install-treesitter on first use
(use-package kdl-mode
  :ensure t
  :mode "\\.kdl\\'")

;;; Builtins
(use-package emacs
  :ensure nil
  :hook
  (prog-mode . (lambda () (setq truncate-lines t))); prevent long line warpping in prog modes
  ;; Disable electric-pair in Lisp modes
  (emacs-lisp-mode . (lambda () (electric-pair-local-mode -1)))
  (clojure-mode . (lambda () (electric-pair-local-mode -1)))
  (lisp-mode . (lambda () (electric-pair-local-mode -1)))
  :bind
  (:map global-map
	("C-c j" . project-recompile)
	;; ("M-o" . other-window)
	;; ("C-c o" . find-file-at-point) ;; redundant use embark
	("C-c p" . my/switch-to-bb-playground)
	("C-x k" . kill-current-buffer))
  :config
  (winner-mode 1) ; use C-c left/right to go over layouts
  (global-auto-revert-mode 1)
  (setq auto-revert-use-notify t) ;; instatnt autorevert
  (setq global-auto-revert-non-file-buffers t)
  (setq auto-revert-verbose nil)
  (setq auto-revert-avoid-polling nil)  ; Add this
  (setq auto-revert-interval 0.25)         ; Add this (check every 1 second)
  (setq scroll-margin 5)
  (setq compilation-always-kill t) ;; make rerunning compilation buffer better, i dont get asked each time to quit process between runs
  (setq set-mark-command-repeat-pop t)
  ;; start window management
  (setq switch-to-buffer-obey-display-actions t
	switch-to-buffer-in-dedicated-window 'pop)
  (defalias 'yes-or-no-p 'y-or-n-p)
  (electric-pair-mode 1)
  (global-subword-mode -1)
  (global-superword-mode 1)
  ;; dissable creating lock files, i can now edit the same file from multiple emacs instances which can be bad
  (setq create-lockfiles nil)
  ;;https://blog.chmouel.com/posts/emacs-isearch/
  (defun my-select-window (window &rest _)
    "Select WINDOW for display-buffer-alist"
    (select-window window))
  (setq display-buffer-alist ; used to give occur focus when it opens by default focus is not switched
	'(((or . ((derived-mode . occur-mode)))
           (display-buffer-reuse-window display-buffer-pop-up-window)
           (body-function . my-select-window)
           (dedicated . t)
           (preserve-size . (t . t)))))

  (setq ring-bell-function 'ignore)
  ;; allow all disabled commands without prompting
  (setq disabled-command-function nil)
  ;;This tells Emacs to write all customizations (from `M-x customize` interface) to `~/.emacs.d/custom.el` instead of appending them to your `init.el`.
  (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
  (load custom-file 'noerror)
  ;; Use ripgrep for project search ripgrep
  (setq xref-search-program 'ripgrep)
  (setq-default line-spacing 0.2)
  (set-face-attribute 'default nil
                      :font "JetBrains Mono-10"
                      :weight 'normal
                      :width 'normal)
  :custom
  
  ;; Curfu
  ;; TAB cycle if there are only few candidates
  ;; (completion-cycle-threshold 3)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  ;; (tab-always-indent 'complete)

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not apply to the current mode.  Corfu
  ;; commands are hidden, since they are not used via M-x. This setting is
  ;; useful beyond Corfu.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Vertico
  ;; Enable context menu. `vertico-multiform-mode' adds a menu in the minibuffer
  ;; to switch display modes.
  (context-menu-mode t)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  :config
  (tool-bar-mode -1)      ;; Disable toolbar
  (menu-bar-mode -1)      ;; Disable menu bar
  (scroll-bar-mode -1)    ;; Disable scroll bar
  (tooltip-mode -1)      ;; Disable tooltips
  ;; Disable initial scratch message
  (setq initial-scratch-message nil)
  ;; No blinking cursor
  (blink-cursor-mode -1)
  (setq inhibit-startup-message t)
  ;; Put auto-save files in a dedicated directory
  (setq auto-save-file-name-transforms
	`((".*" ,(concat user-emacs-directory "auto-save/") t)))

  ;; Create the directory if it doesn't exist
  (make-directory (concat user-emacs-directory "auto-save/") t)

  ;; Put backup files in a dedicated directory
  (setq backup-directory-alist
	`((".*" . ,(concat user-emacs-directory "backup/"))))

  (make-directory (concat user-emacs-directory "backup/") t)
  )
(use-package eglot
  :ensure t
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-initiated-edits nil)
  :bind
  (:map eglot-mode-map
	("C-c l a" . eglot-code-actions)
	("C-c l r" . eglot-rename)
	("C-c l f" . eglot-format)
	("C-c l d" . eglot-find-declaration)
	("C-c l i" . eglot-find-implementation)
	("C-c l t" . eglot-find-typeDefinition)
	("C-c l h" . eldoc)
	("C-c l s" . eglot-shutdown)
	("C-c l R" . eglot-reconnect)))
;;;; Debugger
(use-package gdb-mi
  :ensure nil  ; built-in package
  :demand t
  :init
  ;; Create the keymap before package loads
  (defvar debug-prefix-map (make-sparse-keymap)
    "Keymap for debug commands.")
  :bind-keymap
  ("C-c d" . debug-prefix-map)    
  :config
  (which-key-add-key-based-replacements
    "C-c d"  "+debug")
  ;; Enable the enhanced multi-window debugging layout
  (setq gdb-many-windows t)
  (setq gdb-show-main t)
  
  ;; Better variable display and IO handling
  (setq gdb-use-separate-io-buffer t)
  (setq gdb-display-io-nopopup t)
  
  ;; Enable mouse support and tooltips
  (setq gdb-mouse-select-breakpoint t)
  (setq gud-tooltip-mode t)
  
  ;; Source buffer settings
  (setq gdb-show-changed-values t)  ; Highlight changed variables
  (setq gdb-delete-out-of-scope t)  ; Clean up out-of-scope variables
  
  :bind (:map debug-prefix-map
              ("g" . gdb)
              ("r" . gud-run)
              ("n" . gud-next)
              ("s" . gud-step)
              ("b" . gud-break)
              ("k" . gud-remove)
              ("c" . gud-cont)
              ("f" . gud-finish)
              ("u" . gud-until)
              ("<up>" . gud-up)
              ("<down>" . gud-down)
              ;; GDB-specific enhancements
	      ("W" . gdb-many-windows)
              ("w" . gud-watch)
              ("p" . gud-print)
              ("q" . gdb-quit))
  
  ;; Repeat map for debugging navigation
  (:repeat-map gud-repeat-map
	       ;; Step commands (most commonly repeated)
	       ("n" . gud-next)
	       ("s" . gud-step)
	       ("c" . gud-cont)
	       ("f" . gud-finish)
	       ("u" . gud-until)
	       ;; Stack navigation
	       ("<up>" . gud-up)
	       ("<down>" . gud-down)
	       ;; Quick inspection
	       ("p" . gud-print)
	       ("w" . gud-watch)
	       ("b" . gud-break)
	       ("k" . gud-remove)
	       ("r" . gud-run)
	       :exit
	       ;; Exit repeat mode for setup commands
	       ("q" . gdb-quit))
  
  ;; Auto-enable many-windows mode when starting GDB
  :hook (gdb-mode . gdb-many-windows-mode))
(use-package ibuffer
  :bind ("C-x C-b" . ibuffer)
  :config (setq ibuffer-expert t))

(use-package which-key
  :custom
  (which-key-mode 1))

(use-package ediff
  :ensure nil
  :config
  ;; dont open external frame with ediff
  (setq ediff-window-setup-function 'ediff-setup-windows-plain))

(use-package repeat
  :custom
  (repeat-mode +1))

(use-package project
  :ensure nil
  :preface
  (defun my/project-refresh ()
    (interactive)
    (project-remember-projects-under "~/repos" t)))

(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)
         ("C-c f l" . flymake-show-buffer-diagnostics)
         ("C-c f p" . flymake-show-project-diagnostics)))

(use-package corfu
  :ensure t
  :after orderless
  :custom
  ;; Make the popup appear quicker
  (corfu-popupinfo-delay '(0.5 . 0.5))
  ;; Always have the same width
  (corfu-min-width 80)
  (corfu-max-width corfu-min-width)
  (corfu-count 14)
  (corfu-scroll-margin 4)
  ;; Have Corfu wrap around when going up
  (corfu-cycle t)
  (corfu-preselect-first t)
  :config
  ;; TODO move to :bind
  (define-key corfu-map (kbd "M-p") #'corfu-popupinfo-scroll-down) ;; corfu-next
  (define-key corfu-map (kbd "M-n") #'corfu-popupinfo-scroll-up)  ;; corfu-previous
  (setq corfu-auto t
	corfu-quit-no-match 'separator) 
  :init

  ;; Recommended: Enable Corfu globally.  Recommended since many modes provide
  ;; Capfs and Dabbrev can be used globally (M-/).  See also the customization
  ;; variable `global-corfu-modes' to exclude certain modes.
  (global-corfu-mode)

  ;; Enable optional extension modes:
  (corfu-history-mode)
  (corfu-popupinfo-mode))
;; Enable Corfu completion UI
;; See the Corfu README for more configuration tips.
(use-package corfu
  :init
  (global-corfu-mode))

;; Add extensions
(use-package cape
  :ensure t
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Press C-c p ? to for help.
  :bind ("M-<tab>" . cape-prefix-map) ;; Alternative key: M-<tab>, M-p, M-+
  ;; Alternatively bind Cape commands individually.
  ;; :bind (("C-c p d" . cape-dabbrev)
  ;;        ("C-c p h" . cape-history)
  ;;        ("C-c p f" . cape-file)
  ;;        ...)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; first function returning a result wins.  Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  ;; (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  ;; (add-hook 'completion-at-point-functions #'cape-elisp-block)
  ;; (add-hook 'completion-at-point-functions #'cape-history)
  ;; ...
  )

;;; Theme
(use-package doom-themes
  :ensure t
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold nil)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic nil) ; if nil, italics is universally disabled
  :config
  (load-theme 'doom-zenburn t)
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;;; Modline
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  ;; Display date and time
  (setq display-time-format "%d, Week %U | %H:%M")
  (display-time-mode 1)
  ;; Display battery
  (display-battery-mode 1))

;; Config file modes
(use-package markdown-mode
  :ensure t)

;;; Version control
(use-package magit
  :ensure t
  :demand t
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :config
  ;; Make project.el use magit
  (with-eval-after-load 'project
    (define-key project-prefix-map "v" 'magit-project-status)
    (add-to-list 'project-switch-commands '(magit-project-status "Magit") t)))
(use-package git-timemachine
  :ensure t
  :demand t
  :bind ("C-x v t" . git-timemachine)
  :config
  ;; Show abbreviated commit hash in header line
  (setq git-timemachine-show-minibuffer-details t)
  ;; Automatically kill timemachine buffer when quitting
  (setq git-timemachine-quit-to-invoking-buffer t))
(use-package git-gutter
  :ensure t
  :demand t
  :bind-keymap ("C-c h" . my/git-gutter-repeat-map)
  :bind
  (:repeat-map my/git-gutter-repeat-map
	       ("n" . git-gutter:next-hunk)
	       ("p" . git-gutter:previous-hunk)
	       ("k" . git-gutter:revert-hunk)
	       ("=" . git-gutter:popup-hunk)
	       ("m" . git-gutter:mark-hunk)
	       ("s" . git-gutter:stage-hunk)
	       :exit
	       ("d" . vc-dir)
	       ("v" . vc-next-action))
  :config
  (which-key-add-key-based-replacements
    "C-c h"  "+git-hunk")
  (setq git-gutter:ask-p nil)
  (global-git-gutter-mode +1))
(use-package consult-gh
  :ensure t
  :after consult
  :custom
  (consult-gh-default-clone-directory "~/repos")
  (consult-gh-show-preview t)
  (consult-gh-preview-key "C-o")
  (consult-gh-repo-action #'consult-gh--repo-browse-files-action)
  (consult-gh-large-file-warning-threshold 2500000)
  (consult-gh-confirm-name-before-fork nil)
  (consult-gh-confirm-before-clone t)
  (consult-gh-notifications-show-unread-only nil)
  (consult-gh-default-interactive-command #'consult-gh-transient)
  (consult-gh-prioritize-local-folder nil)
  (consult-gh-group-dashboard-by :reason)
  ;;;; Optional
  (consult-gh-repo-preview-major-mode nil) ; show readmes in their original format
  (consult-gh-preview-major-mode 'org-mode) ; use 'org-mode for editing comments, commit messages, ...
  :config
  ;; Remember visited orgs and repos across sessions
  (add-to-list 'savehist-additional-variables 'consult-gh--known-orgs-list)
  (add-to-list 'savehist-additional-variables 'consult-gh--known-repos-list)
  ;; Enable default keybindings (e.g. for commenting on issues, prs, ...)
  (consult-gh-enable-default-keybindings))
(use-package consult-gh-embark
  :ensure t
  :after consult-gh
  :config
  (consult-gh-embark-mode +1))

;;; AI
(use-package gptel
  :ensure t
  :demand t
  ;;   :hook ((gptel-post-stream . gptel-auto-scroll)
  ;; (gptel-post-response-functions . gptel-end-of-response))
  :init
  ;; Create the keymap before package loads
  (defvar gptel-prefix-map (make-sparse-keymap)
    "Keymap for gptel commands.")
  :bind-keymap
  ("C-c f" . gptel-prefix-map)    
  :bind
  ( :map gptel-prefix-map
    ("r" . gptel-rewrite)
    ("m" . gptel-menu)
    ("a" . gptel-add)
    ("c" . gptel-context-remove-all)
    ("A" . gptel-add-file)
    ("f" . gptel-send-with-options)
    ("F" . gptel-send))
  :config
  (which-key-add-key-based-replacements
    "C-c f"  "+gptel")
  (defun gptel-send-with-options (&optional arg)
    "Send query from minibuffer to aichat gptel buffer."
    (interactive "P")
    (if arg
	(call-interactively 'gptel-menu)
      ;; Ensure we have a proper gptel buffer
      (let ((buffer (get-buffer "aichat")))
	(unless buffer
          (setq buffer (get-buffer-create "aichat"))
          (with-current-buffer buffer
            (funcall gptel-default-mode)
            (gptel-mode 1)
            (setq gptel--backend-name gptel-backend
                  gptel--model gptel-model)))
	;; Send with minibuffer input to buffer
	(let ((transient-current-command 'gptel-menu))
          (gptel--suffix-send '("m" "baichat"))))))
  (setq gptel-default-mode 'org-mode)
  (setq gptel-model 'claude-sonnet-4-5-20250929
	gptel-backend (gptel-make-anthropic "AICHAT"
			:stream t
			:models '(claude-sonnet-4-5-20250929)
			:key (getenv "ANTHROPIC_API_KEY"))))

(use-package x509-mode
  :ensure t)

(use-package jwt
  :ensure t
  :commands (jwt-decode jwt-encode))

;; Used to get direnv working when launching in sway


;;---COMPLETION---start
(use-package vertico
  :ensure t
  :custom
  ;; (vertico-scroll-margin 0) ;; Different scroll margin
  ;; (vertico-count 20) ;; Show more candidates
  ;; (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  ;; instead of enabling full desktop mode i just want to save register and kill-ring between restarts
  (setq savehist-additional-variables '(register-alist kill-ring))
  (savehist-mode 1))

(use-package orderless
  :ensure t
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

;; Enable rich annotations using the Marginalia package
(use-package marginalia
  :ensure t
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))
;;---COMPLETION---end
(use-package consult
  :ensure t
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
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
         ("M-j" . consult-register-load)
         ("M-i" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-j" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
	 ("M-g a" . consult-yank-pop)
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-s M-s" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-fd)
         ("M-s c" . consult-locate)
         ("M-s g" . consult-ripgrep)
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
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config
  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'nil)
  (setq consult-preview-key "C-.")
  (consult-customize
   consult-theme consult-man consult-org-agenda :preview-key '(:debounce 0.2 any))
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  ;; (consult-customize
  ;;  consult-theme :preview-key '(:debounce 0.2 any)
  ;;  consult-ripgrep consult-git-grep consult-grep consult-man
  ;;  consult-bookmark consult-recent-file consult-xref
  ;;  consult--source-bookmark consult--source-file-register
  ;;  consult--source-recent-file consult--source-project-recent-file
  ;;  ;; :preview-key "M-."
  ;;  :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )

(use-package embark-consult
  :ensure t
  :after consult)


(use-package embark
  :ensure t

  :bind
  (("C-;" . embark-act)         ;; pick some comfortable binding
   ("M-." . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc. You may adjust the
  ;; Eldoc strategy, if you want to see the documentation from
  ;; multiple providers. Beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  ;; Add Embark to the mouse context menu. Also enable `context-menu-mode'.
  ;; (context-menu-mode 1)
  ;; (add-hook 'context-menu-functions #'embark-context-menu 100)

  :config
  ;; Integrate Avy and Embark

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
	       '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;;---NOTE TAKING---start


;;; Terminal
(use-package eat
  :ensure t
  :hook ((eshell-load . eat-eshell-mode)
         (eshell-load . eat-eshell-visual-command-mode)))
(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode))
(use-package exec-path-from-shell
  :ensure t
  :config
  ;; set all variables that should be copied
  (dolist (var '("ANTHROPIC_API_KEY"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;;; Window management
(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window))
  :config
  (setq
   aw-scope 'frame
   aw-ignore-current t
   aw-ignore-on t
   aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))
(use-package popper
  :ensure t ; or :straight t
  :bind (("C-`"   . popper-toggle)
         ("M-`"   . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-window-height 25
	popper-display-function #'popper-display-popup-at-bottom
	popper-reference-buffers '("\\*Messages\\*"
				   "Output\\*$"
				   "*just.*\\*$"
				   "*eldoc*"
				   "\\*AICHAT\\*"
				   "\\*Async Shell Command\\*"
				   "^\\*eshell.*\\*$" eshell-mode ;eshell as a popup
				   Man-mode
				   help-mode
				   compilation-mode))
  (popper-mode +1)
  (popper-echo-mode +1))

;;; Note taking
(use-package org
  :ensure t
  :demand t
  :hook (org-mode . visual-line-mode)
  :init
  ;; Create the keymap before package loads
  (defvar note-prefix-map (make-sparse-keymap)
    "Keymap for note commands.")
  :bind-keymap
  ("C-c n" . note-prefix-map)    
  :config
  (which-key-add-key-based-replacements
    "C-c n"  "+note")
  (setq org-startup-indented t)
  ;; Set default directory for org files
  (setq org-directory "~/org-agenda")
  (setq org-default-todo-file (expand-file-name "tasks.org" org-directory))

  ;; Agenda files location
  (setq org-agenda-files (list org-directory))
  
  ;; Create directory if it doesn't exist
  (unless (file-exists-p org-directory)
    (make-directory org-directory t))
  (setq org-capture-templates
	'(("T" "Todo with link" entry
           (file org-default-todo-file)
           "* TODO %?\n %U\n Created from: %a\n  %i"
           :empty-lines 1)
          
          ("t" "Todo without link" entry
           (file org-default-todo-file)
           "* TODO %?\n  %U"
           :empty-lines 1)))  
  :bind (:map note-prefix-map
	      ("a" . consult-org-agenda)
	      ("t" . (lambda () (interactive) (org-capture nil "t")))
	      ("T" . (lambda () (interactive) (org-capture nil "T")))))
(use-package denote
  :ensure t
  :demand t
  :after org
  :hook (dired-mode . denote-dired-mode)
  :bind
  (:map note-prefix-map
	("n" . denote)
	("N" . denote-region)
	("r" . denote-rename-file)
	("l" . denote-link)
	("b" . denote-backlinks)
	("d" . (lambda () (interactive) (dired denote-directory)))
	("D" . denote-dired)
	("g" . denote-grep))
  :config
  (setq denote-directory (expand-file-name "~/notes/"))

  ;; Automatically rename Denote buffers when opening them so that
  ;; instead of their long file name they have, for example, a literal
  ;; "[D]" followed by the file's title.  Read the doc string of
  ;; `denote-rename-buffer-format' for how to modify this.
  (denote-rename-buffer-mode 1))
;;---NOTE TAKING---end


;;---PROGRAMMING---end
(use-package isearch
  :ensure nil
  :bind
  ("C-M-s" . isearch-forward-other-window)
  ("C-M-r" . isearch-backward-other-window)
  :config
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
          (other-window (- next))))))            )

(use-package isearch
  :ensure nil
  :defer t
  :bind
  (("M-s r" . query-replace-regexp)
   :map isearch-mode-map
   ;; TODO this do not wok just he to show how to add to map
   ("R" . isearch-query-replace-regexp)))

(use-package just-mode
  :ensure t)

(use-package justl
  :ensure t
  :demand t
  :init
  (defvar justl-prefix-map (make-sparse-keymap)
    "Keymap for justl commands.")
  :bind-keymap
  ("C-c r" . justl-prefix-map)
  :bind
  (:map justl-prefix-map
	("m" . justl)
	("d" . justl-exec-default-recipe)
	("r" . justl-exec-recipe-in-dir))
  :config
  (which-key-add-key-based-replacements
    "C-c r"  "+just"))



;; disable other language mode formatters and use apheleia for all formatting
(use-package apheleia
  :ensure t
  :demand t
  :config
  (apheleia-global-mode +1)
  :hook
  (prog-mode . apheleia-mode))

;; redundant use M-g n/p
;; (use-package flymake
;;   :bind (:map prog-mode-map
;;               ("M-n" . flymake-goto-next-error)
;;               ("M-p" . flymake-goto-prev-error)))






;;; Containers
(use-package kele
  :ensure t
  :if (my-package-enabled-p 'k8)
  :config
  (kele-mode 1))
(use-package dockerfile-mode
  :ensure t
  :if (my-package-enabled-p 'docker))
(use-package docker
  :ensure t
  :if (my-package-enabled-p 'docker)
  :bind ("C-c d" . docker))

;;; Zig
(use-package zig-mode
  :hook ((zig-mode) . eglot-ensure)
  :if (my-package-enabled-p 'zig)
  :bind (:map zig-mode-map
	      ("C-c C-c t" . my/zig-build-test)
	      ("C-c C-c l" . my/zig-test-file-local)
	      ("C-c C-c r" . my/zig-build-test-filter-at-point)
	      ("C-c C-c f" . my/zig-test-filter-at-point))
  :config
  (defun my/zig-test-file-local ()
    "Set compile command for zig test on current file and trigger compilation."
    (interactive)
    (let* ((project-root (or (project-root (project-current))
                             default-directory))
           (relative-path (file-relative-name (buffer-file-name) project-root)))
      (setq compile-command (format "zig test %s" relative-path))
      (let ((default-directory project-root))
	(compile compile-command))))

  (defun my/zig-test-filter-at-point ()
    "Run zig test with filter using quoted string at point."
    (interactive)
    (let* ((project-root (or (project-root (project-current))
                             default-directory))
           (relative-path (file-relative-name (buffer-file-name) project-root))
           (quoted-string (thing-at-point 'string t)))
      (if quoted-string
	  (progn
            (setq compile-command 
                  (format "zig test %s --test-filter %s" relative-path quoted-string))
	    (let  ((default-directory project-root))
	      (compile compile-command)))
	(message "No quoted string found at point"))))

  ;; I can pass in multiple test-filter might want to extend this to that?
  ;; zig build test -Dtest-filter="parse ls output" -Dtest-filter="next test"
  (defun my/zig-build-test-filter-at-point ()
    "Run zig build test with filter using quoted string at point."
    (interactive)
    (let* ((project-root (or (project-root (project-current))
                             default-directory))
           (relative-path (file-relative-name (buffer-file-name) project-root))
           (quoted-string (thing-at-point 'string t)))
      (if quoted-string
	  (progn
            (setq compile-command 
                  (format "zig build test --summary new -Dtest-filter=%s" quoted-string))
	    (let  ((default-directory project-root))
	      (compile compile-command)))
	(message "No quoted string found at point"))))

  (defun my/zig-build-test ()
    "Set compile command to 'zig build test' and run compilation."
    (interactive)
    (let ((project-root (or (project-root (project-current))
			    default-directory)))
      (setq compile-command "zig build test")
      (let  ((default-directory project-root))
	(compile compile-command))))

  (setq zig-format-on-save nil) ; rely on :editor format instead
  :vc (:url "https://github.com/ziglang/zig-mode" :branch "master")
  :mode "\\.zig\\'")

;;; Clojure
(use-package cider
  :ensure t
  :if (my-package-enabled-p 'clojure)
  :config
  (defun my/cider-jack-in-babashka (&optional project-dir)
    "Start a utility CIDER REPL backed by Babashka, not related to a
specific project."
    (interactive)
    (when (get-buffer "*babashka-repl*")
      (kill-buffer "*babashka-repl*"))
    (when (get-buffer "*bb-playground*")
      (kill-buffer "*bb-playground*"))
    (let ((project-dir (or project-dir user-emacs-directory)))
      (nrepl-start-server-process
       project-dir
       "bb --nrepl-server 0"
       (lambda (server-buf)
	 (set-process-query-on-exit-flag
          (get-buffer-process server-buf) nil)
	 (cider-nrepl-connect
          (list :repl-buffer server-buf
		:repl-type 'clj
		:host (plist-get nrepl-endpoint :host)
		:port (plist-get nrepl-endpoint :port)
		:session-name "babashka"
		:repl-init-function (lambda ()
                                      (setq-local cljr-suppress-no-project-warning t
                                                  cljr-suppress-middleware-warnings t
                                                  process-query-on-exit-flag nil)
                                      (set-process-query-on-exit-flag
                                       (get-buffer-process (current-buffer)) nil)
                                      (rename-buffer "*babashka-repl*")
                                      ;; Create and link playground buffer
                                      (let ((playground-buffer (get-buffer-create "*bb-playground*")))
					(with-current-buffer playground-buffer
                                          (clojure-mode)
					  (insert ";; Babashka Playground\n\n")
					  (insert "(ns bb-malli\n  (:require [babashka.deps :as deps]))\n")
					  (insert"(deps/add-deps '{:deps {metosin/malli {:mvn/version \"0.9.0\"}}})\n")
					  (insert"(require '[malli.core :as malli])\n\n")
					  (insert ";; Your code here\n")
					  (goto-char (point-max)) ; Move cursor to end
                                          (sesman-link-with-buffer playground-buffer '("babashka")))
					(switch-to-buffer playground-buffer)))))))))

  (defun my/switch-to-bb-playground ()
    "Switch to *bb-playground* buffer if it exists, otherwise start babashka REPL and switch to playground."
    (interactive)
    (if (get-buffer "*bb-playground*")
	(switch-to-buffer "*bb-playground*")
      (my/cider-jack-in-babashka)))
  (setq cider-repl-pop-to-buffer-on-connect nil))

;;; Odin
(use-package odin-ts-mode
  :vc (:url "https://github.com/Sampie159/odin-ts-mode" :rev :newest)
  :after apheleia
  :if (my-package-enabled-p 'odin)
  :bind (:map odin-ts-mode-map
	      ("C-c C-c t" . odin-test-at-point)
	      ("C-c C-c r" . odin-run-module)
	      ("C-c C-c c" . odin-check-module))
  :hook ((odin-ts-mode) . eglot-ensure)
  ((odin-ts-mode) . (lambda ()
		      (setq tab-width 4
			    indent-tabs-mode t)))
  :mode ("\\.odin\\'" . odin-ts-mode)
  :config
  (defun odin-run-module ()
    "Run odin run command with current buffer's folder."
    (interactive)
    (let ((folder (file-name-directory (buffer-file-name))))
      (if folder
          (let ((command (format "odin run %s" folder)))
            (compile command))
	(message "Buffer is not associated with a file"))))
  (defun odin-check-module ()
    "Run odin check command with current buffer's folder."
    (interactive)
    (let ((folder (file-name-directory (buffer-file-name))))
      (if folder
          (let ((command (format "odin check %s" folder)))
            (compile command))
	(message "Buffer is not associated with a file"))))
  (defun odin-test-at-point ()
    "Run odin test command with current buffer's folder. If word under cursor exists, add it as test name."
    (interactive)
    (let ((word (thing-at-point 'word t))
          (folder (file-name-directory (buffer-file-name))))
      (if folder
          (let ((command (if word
                             (format "odin test %s -define:ODIN_TEST_NAMES=%s" folder word)
                           (format "odin test %s" folder))))
            (compile command))
	(message "Buffer is not associated with a file"))))
  (add-to-list 'treesit-language-source-alist
               '(odin "https://github.com/tree-sitter-grammars/tree-sitter-odin"))
  (add-to-list 'apheleia-formatters
	       '(odinfmt . ("odinfmt" "-stdin")))
  (add-to-list 'apheleia-mode-alist
	       '(odin-ts-mode . odinfmt))
  ;; (add-to-list 'compilation-error-regexp-alist-alist
  ;;              '(odin-test
  ;; 		 "^\\[ERROR\\].*\\[\\([^:]+\\):\\([0-9]+\\):"
  ;; 		 1 2 nil 2 1))
  ;; (add-to-list 'compilation-error-regexp-alist 'odin-test)
  
  )

;;; Janet
(use-package janet-ts-mode
  :vc (:url "https://github.com/sogaiu/janet-ts-mode"
	    :rev :newest)
  :if (my-package-enabled-p 'janet)
  :bind (:map janet-ts-mode-map
	      ("C-c C-c" . run-judge-at-point))
  :hook
  (janet-ts-mode . (lambda () (electric-pair-local-mode -1)))
  :config
  (defun my-janet-setup-completion ()
    "Setup buffer-based completion for janet-ts-mode."
    (setq-local completion-at-point-functions
		(list #'cape-dabbrev)))

  (defun run-judge-at-point ()
    "Run judge with current buffer's file path and cursor position."
    (interactive)
    (let* ((file (buffer-file-name))
           (line (line-number-at-pos))
           (col (current-column))
           (target (format "%s:%d:%d" file line col)))
      (if file
          (progn
            (when (buffer-modified-p)
              (save-buffer))
            (compile (format "judge -a %s" target)))
	(error "Buffer is not visiting a file"))))

  (add-to-list 'apheleia-formatters
               '(janet-fmt . ("janet" "-e" "(import spork/fmt) (fmt/format-print (file/read stdin :all))")))
  (add-to-list 'apheleia-mode-alist
               '(janet-ts-mode . janet-fmt))
  (setq treesit-language-source-alist
	(if (eq 'windows-nt system-type)
            '((janet-simple
               . ("https://github.com/sogaiu/tree-sitter-janet-simple"
                  nil nil "gcc.exe")))
          '((janet-simple
             . ("https://github.com/sogaiu/tree-sitter-janet-simple")))))

  (when (not (treesit-language-available-p 'janet-simple))
    (treesit-install-language-grammar 'janet-simple)))
(use-package ajrepl
  :vc (:url "https://github.com/sogaiu/ajrepl"
	    :rev :newest)
  :if (my-package-enabled-p 'janet)
  :config
  (add-hook 'janet-ts-mode-hook
	    #'my-janet-setup-completion)
  (add-hook 'janet-ts-mode-hook
            #'ajrepl-interaction-mode))

;;; Go
(use-package go-mode
  :ensure t
  :if (my-package-enabled-p 'go)
  :hook ((go-mode) . eglot-ensure))

;;; Roc
;; M-x treesit-install-language-grammar
;; there is a roc-ts-install-treesitter-grammar
(use-package roc-ts-mode
  :ensure t
  :if (my-package-enabled-p 'roc)
  :mode ("\\.roc\\'" . roc-ts-mode)
  :hook ((roc-ts-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '(roc-ts-mode . ("roc_language_server"))))

;;; Utils
(use-package chezmoi
  :ensure t
  :demand t
  :vc (:url "https://github.com/tuh8888/chezmoi.el"
            :rev :newest)
  :init
  ;; Create the keymap before package loads
  (defvar chezmoi-prefix-map (make-sparse-keymap)
    "Keymap for chezmoi commands.")
  :bind-keymap
  ("C-c ." . chezmoi-prefix-map)    
  :bind
  (:map chezmoi-prefix-map
        ("f" . chezmoi-find)
        ("a" . chezmoi-dired-add-marked-file)
        ("o" . chezmoi-open-other)
        ("d" . chezmoi-diff)
        ("e" . chezmoi-ediff)
        ("v" . chezmoi-magit-status))
  :config
  (which-key-add-key-based-replacements
    "C-c ." "+chezmoi"))
(use-package chezmoi-dired
  :after chezmoi
  :ensure nil
  :load-path "elpa/chezmoi/extensions/")
(use-package chezmoi-magit
  :after chezmoi
  :ensure nil
  :load-path "elpa/chezmoi/extensions/")
(use-package nov
  :ensure t
  :mode ("\\.epub\\'" . nov-mode)
  :config
  (setq nov-text-width 80
	nov-variable-pitch t)
  :hook
  (nov-mode . visual-line-mode))
