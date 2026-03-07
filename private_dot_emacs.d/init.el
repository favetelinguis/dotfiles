;;; -*- lexical-binding: t; -*-

;; This file is organized by outlining using ;;; and ;;;; etc to represent levels,
;; then a command such as consult-outline bound to M-s M-s can be used to navigate.

;;; Elpaca
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))
(setq elpaca-lock-file (expand-file-name "elpaca-lock-file.el" user-emacs-directory))
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;; Make sure this is early in init so env vars are avaliable for others needing them
(use-package exec-path-from-shell
  :ensure t
  :config
  ;; should prob have some conditional here to only load when demonp or othercheck github repo for info
  ;; however this is the solution that works most often for me atm
  (dolist (var '("NIRI_SOCKET"
		 "OPENAI_API_KEY"
		 "TAVILY_API_KEY"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))


;; Auto-save only Claude Code temp files (adjust pattern as needed)
(add-hook 'server-visit-hook
          (lambda ()
            (when (string-match-p "/tmp/.*claude" (or buffer-file-name ""))
              (setq buffer-save-without-query t))))

;;; Update builtins

(use-package transient
  :ensure t)

(use-package jsonrpc
  :ensure t)

;;; Builtins

(use-package savehist
  :init
  ;; save lots of good things between restarts
  (setq savehist-additional-variables '(register-alist kill-ring))
  (savehist-mode 1))

;; This is added only for keybindings that should override all other keybindings
(use-package emacs
  :ensure nil
  :init
  ;; Create the override keymap and mode BEFORE :bind
  (defvar my-override-mode-map (make-sparse-keymap)
    "Keymap for overriding all other keymaps.")
  
  (define-minor-mode my-override-mode
    "Minor mode to override all keybindings."
    :init-value t
    :global t
    :keymap my-override-mode-map)
  
  :bind (:map my-override-mode-map
              ("M-q" . my-iflipb-kill-current-buffer)
              ("M-j" . my/pop-to-special-buffer)
              ("M-k" . iflipb-previous-buffer)
              ("C-M-j" . consult-recent-file))
  
  :config
  ;; This is KEY - it gives your keymap highest priority
  (add-to-list 'emulation-mode-map-alists 
               `((my-override-mode . ,my-override-mode-map)))
  
  ;; Enable the mode
  (my-override-mode 1))

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
	("M-g o" . ff-find-other-file)
	("M-g O" . ff-find-other-file-other-window)
	("M-`" . window-toggle-side-windows)
	("M-o" . other-window)
	)
  :config
  (recentf-mode 1)
  (setq-default line-spacing 0.2)
  (set-face-attribute 'default nil
		      :family "JetBrains Mono"
		      :height 115
		      :weight 'normal
		      :width 'normal)
  ;; Display date and time
  (setq display-time-format "%d, Week %V | %H:%M")
  (display-time-mode 1)
  ;; Display battery
  (display-battery-mode 1)
  (winner-mode 1) ; use C-c left/right to go over layouts
  (global-auto-revert-mode 1)
  (setq mode-line-position
	'("%l:%c/" 
          (:eval (format "%d" (count-lines (point-min) (point-max))))))
  (setq auto-revert-use-notify t) ;; instatnt autorevert
  (setq global-auto-revert-non-file-buffers t)
  (setq auto-revert-verbose nil)
  (setq auto-revert-avoid-polling nil)  ; Add this
  (setq auto-revert-interval 0.25)         ; Add this (check every 1 second)
  (setq scroll-margin 5)
  (setq compilation-always-kill t) ;; make rerunning compilation buffer better, i dont get asked each time to quit process between runs
  (setq compilation-scroll-output t)
  (add-hook 'compilation-filter-hook ; get rid of all ansi controlls in compilation buffer
	    (lambda ()
	      (ansi-color-filter-region (point-min) (point))))
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
   '(read-only t cursor-intangible t face minibuffer-prompt)))

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

(use-package eglot
  :ensure nil
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-initiated-edits nil)
  :config
  (add-to-list 'eglot-ignored-server-capabilities :inlayHintProvider)
  :bind
  (:map eglot-mode-map ; C-h . for eldoc M-.,? for xref
	("C-c a" . eglot-code-actions)
	("C-c r" . eglot-rename)))

;;; Debugger

(use-package gud
  :ensure nil
  :config
  (defun my-gud-display-line-advice (orig-fun &rest args)
    "Make gud-display-line reuse existing windows."
    (let ((display-buffer-overriding-action
           '((display-buffer-reuse-window 
	      display-buffer-use-some-window)
             (inhibit-same-window . t))))
      (apply orig-fun args)))

  (advice-add 'gud-display-line :around #'my-gud-display-line-advice))

(use-package gdb-mi
  :ensure nil  ; built-in package
  :demand t
  :config
  ;; Stop asking when staring gdb might need to use if using remote debugging
  (setq gdb-debuginfod-enable-setting nil)
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
  )

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
  :ensure t
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)
         ("C-x p D" . flymake-show-project-diagnostics)))

;;; In-Buffer Completion 
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
  (define-key corfu-map (kbd "M-p") #'corfu-popupinfo-scroll-down) ;; corfu-next
  (define-key corfu-map (kbd "M-n") #'corfu-popupinfo-scroll-up)  ;; corfu-previous
  (setq corfu-auto nil ; set to t to autoshow
	corfu-quit-no-match 'separator) 
  :init

  ;; Recommended: Enable Corfu globally.  Recommended since many modes provide
  ;; Capfs and Dabbrev can be used globally (M-/).  See also the customization
  ;; variable `global-corfu-modes' to exclude certain modes.
  (global-corfu-mode)

  ;; Enable optional extension modes:
  (corfu-history-mode)
  (corfu-popupinfo-mode))

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
(use-package zenburn-theme
  :ensure t
  :config
  (load-theme 'zenburn t) ;; this needs to come before any overrides
  (zenburn-with-color-variables
    (custom-theme-set-faces
     'zenburn
     `(git-gutter:added ((t (:foreground ,zenburn-green :background unspecified))))
     `(git-gutter:deleted ((t (:foreground ,zenburn-red :background unspecified))))
     `(git-gutter:modified ((t (:foreground ,zenburn-cyan :background unspecified)))))))

;; Config file modes
(use-package markdown-mode
  :ensure t
  :hook (markdown-mode . visual-line-mode)
  :after apheleia
  :config
  ;; Apheleia formatter (Prettier)
  (add-to-list 'apheleia-formatters
               '(prettier-md . ("prettier" "--parser" "markdown")))
  (add-to-list 'apheleia-mode-alist '(gfm-mode . prettier-md))
  (add-to-list 'apheleia-mode-alist
               '(markdown-mode . prettier-md)))

;;; Version control
(use-package magit
  :ensure t
  :demand t
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch)
	 :map vc-prefix-map
	 ("v" . magit-status)
	 ("d" . magit-diff)
	 ("l" . magit-log)
	 ("b" . magit-blame)
	 ("f" . magit-file-dispatch))
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  :config
  (setcdr vc-prefix-map nil) ;; clear the original vc-prefix-map so i can use it for magit etc
  ;; Make project.el use magit
  (with-eval-after-load 'project
    (setq project-switch-commands
	  (assoc-delete-all 'project-vc-dir project-switch-commands))
    (define-key project-prefix-map "v" 'magit-project-status)
    (add-to-list 'project-switch-commands '(magit-project-status "Magit") t)))

(use-package git-timemachine
  :ensure t
  :demand t
  :bind (:map vc-prefix-map
	      ("t" . git-timemachine))
  :config
  ;; Show abbreviated commit hash in header line
  (setq git-timemachine-show-minibuffer-details t)
  ;; Automatically kill timemachine buffer when quitting
  (setq git-timemachine-quit-to-invoking-buffer t))

(use-package git-gutter
  :ensure t
  :demand t
  :bind-keymap ("C-x v h" . my/git-gutter-repeat-map)
  :bind
  (:repeat-map my/git-gutter-repeat-map
	       ("n" . git-gutter:next-hunk)
	       ("p" . git-gutter:previous-hunk)
	       ("k" . git-gutter:revert-hunk)
	       ("=" . git-gutter:popup-hunk)
	       ("m" . git-gutter:mark-hunk)
	       ("s" . git-gutter:stage-hunk)
	       :exit
	       ("v" . magit-status)
	       ("f" . magit-file-dispatch))
  :config
  (which-key-add-key-based-replacements
    "C-x v h"  "git-hunk")
  (setq git-gutter:ask-p nil)
  (global-git-gutter-mode +1))

;;; AI
;; override 
;; ~/.emacs.d/local_only/init-local.el
;;(with-eval-after-load 'agent-shell
;; choose Claude Code globally
;;(setopt agent-shell-preferred-agent-config 'claude-code)

;; auth style examples (pick one)
;; (setopt agent-shell-anthropic-authentication
;;         (agent-shell-anthropic-make-authentication :login t))
;; or:
;; (setopt agent-shell-anthropic-authentication
;;         (agent-shell-anthropic-make-authentication
;;          :api-key (getenv "ANTHROPIC_API_KEY")))
;;)
(use-package agent-shell
  :ensure t
  :defer nil
  :bind
  (:map agent-shell-mode-map
	("C-c C-k" . agent-shell-clear-buffer)
	("C-c C-o" . agent-shell-insert-shell-command-output)
	("C-c C-s" . agent-shell-send-screenshot))
  :config
  (setq agent-shell-openai-authentication
	(agent-shell-openai-make-authentication :login t))
  (setq agent-shell-opencode-authentication
        (agent-shell-opencode-make-authentication :none t)) ;; make sure api key is NOT used do opencode auth login
  (setq agent-shell-opencode-default-model-id "openai/gpt-5.3-codex")
  (setq agent-shell-preferred-agent-config
        (agent-shell-opencode-make-agent-config))
  (setq agent-shell-opencode-default-session-mode-id "plan")
  (setq ;; agent-shell-show-usage-at-turn-end t
   agent-shell-header-style 'text
   agent-shell-show-context-usage-indicator t
   agent-shell-session-strategy 'prompt
   ;;      agent-shell-preferred-agent-config (agent-shell-openai-make-codex-config) 
   ;;	agent-shell-prefer-viewport-interaction t
   agent-shell-show-welcome-message nil)
  (define-key project-prefix-map "a" 'agent-shell)
  (add-to-list 'project-switch-commands '(agent-shell-new-shell "Agent Shell" ?a) t))

;;; Completions stack vertico - orderless - marginalia - consult
(use-package vertico
  :ensure t
  :custom
  ;; (vertico-scroll-margin 0) ;; Different scroll margin
  ;; (vertico-count 20) ;; Show more candidates
  ;; (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

(use-package orderless
  :ensure t
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

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

(use-package consult
  :ensure t
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
	 ;;         ("C-c k" . consult-kmacro)
	 ;;         ("C-c m" . consult-man)
	 ;;         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ("C-x r j" . consult-register-load)
         ("C-x r SPC" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-x r r" . consult-register)
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

;;; Terminal

(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode))

;;; Note taking
(use-package org
  :ensure t
  :demand t
  :hook (org-mode . visual-line-mode)
  :config
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
           :empty-lines 1
	   :prepend t)
          
          ("t" "Todo without link" entry
           (file org-default-todo-file)
           "* TODO %?\n  %U"
           :empty-lines 1
	   :prepend t))))

(use-package denote
  :ensure t
  :demand t
  :after org
  :hook (dired-mode . denote-dired-mode)
  :config
  (setq denote-directory (expand-file-name "~/notes/"))

  ;; Automatically rename Denote buffers when opening them so that
  ;; instead of their long file name they have, for example, a literal
  ;; "[D]" followed by the file's title.  Read the doc string of
  ;; `denote-rename-buffer-format' for how to modify this.
  (denote-rename-buffer-mode 1))

;;; Buffer management
(use-package iflipb
  :ensure t
  :custom (iflipb-buffer-list-function #'buffers-associated-with-frame)
  :config
  (defun buffers-associated-with-frame (&optional frame)
    "Return non-agent-shell buffers associated with FRAME (shown or buried there)."
    (let* ((frame (or frame (selected-frame)))
           (buffers (delete-dups
                     (append (frame-parameter frame 'buffer-list)
                             (frame-parameter frame 'buried-buffer-list)))))
      (seq-filter
       (lambda (buf)
	 (not (with-current-buffer buf
		(derived-mode-p 'agent-shell-mode))))
       buffers)))
  (defun my-iflipb-kill-current-buffer ()
    "Kill the current buffer without prompting and maintain iflipb state."
    (interactive)
    (kill-buffer (current-buffer))
    (if (iflipb-first-iflipb-buffer-switch-command)
	(setq last-command 'kill-buffer)
      (if (< iflipb-current-buffer-index (length (iflipb-interesting-buffers)))
          (iflipb-select-buffer iflipb-current-buffer-index)
	(iflipb-select-buffer (1- iflipb-current-buffer-index)))
      (setq last-command 'iflipb-kill-buffer))))

;;; C++
(use-package cc-mode ;; use suckless style for c code
  :hook (c-mode . (lambda ()
                    (setq tab-width 8)
                    (setq c-basic-offset 8)
                    (setq indent-tabs-mode t))))

(use-package cmake-mode
  :ensure t
  :mode (("CMakeLists\\.txt\\'" . cmake-mode)
         ("\\.cmake\\'" . cmake-mode)))

;;; Misc modes
(use-package x509-mode
  :ensure t)

(use-package jwt
  :ensure t
  :commands (jwt-decode jwt-encode))

;; OBS will need to run kdl-install-treesitter on first use
(use-package kdl-mode
  :ensure t
  :mode "\\.kdl\\'"
  :hook
  (kdl-mode . (lambda ()
                (setq-local indent-line-function #'indent-relative-first-indent-point)))
  (kdl-mode . (lambda ()
		(setq tab-width 4)))
  :config
  (add-to-list 'apheleia-formatters
	       '(kdlfmt . ("kdlfmt" "format" "-")))
  (add-to-list 'apheleia-mode-alist
	       '(kdl-mode . kdlfmt)))

(use-package apheleia
  :ensure t
  :demand t
  :config
  (apheleia-global-mode +1)
  :hook
  (prog-mode . apheleia-mode))

(use-package dockerfile-mode
  :ensure t
  :mode ("Dockerfile\\'" . dockerfile-mode))

(use-package just-mode
  :ensure t
  :mode ("/[Jj]ustfile\\'" . just-mode))

(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

;;; Containers

(use-package kubed
  :ensure t
  :if (executable-find "kubectl")
  :bind-keymap
  ("C-c k" . kubed-prefix-map))

(use-package docker
  :ensure t
  :if (executable-find "docker"))

;;; Linux

(use-package journalctl-mode
  :ensure t
  :if (executable-find "journalctl")
  :bind (("C-c t" . journalctl)))

;;;; Dotfile management

(use-package chezmoi
  :ensure  (:host github
		  :repo "https://github.com/tuh8888/chezmoi.el"
		  :files ("*.el"
			  "extensions/chezmoi-dired.el"
			  "extensions/chezmoi-magit.el"
			  "extensions/chezmoi-ediff.el"))
  :demand t
  :if (executable-find "chezmoi")
  :init
  (require 'chezmoi-dired)
  (require 'chezmoi-magit)
  (require 'chezmoi-ediff))

;;; Keymap C-z
(defvar-keymap my-prefix-note-map
  :doc "My prefix key map for notes."
  "a" #'consult-org-agenda
  "t" (lambda () (interactive) (org-capture nil "t"))
  "T" (lambda () (interactive) (org-capture nil "T"))
  "n" #'denote
  "N" #'denote-region
  "r" #'denote-rename-file
  "l" #'denote-link-or-create
  "b" #'denote-backlinks
  "d" (lambda () (interactive) (dired (car(denote-directories))))
  "f" (lambda () (interactive) (consult-fd (car(denote-directories))))
  "g" (lambda () (interactive) (consult-ripgrep (car(denote-directories)))))

(defvar-keymap my-prefix-dotfile-map
  :doc "My prefix key map for dotfiles."
  "f" #'chezmoi-find
  "o" #'chezmoi-open-other
  "v" #'chezmoi-magit-status
  "e" #'chezmoi-ediff
  "w" #'chezmoi-write
  "a" #'chezmoi-dired-add-marked-files
  "d" #'chezmoi-diff)


(defvar-keymap my-prefix-map
  :doc "My prefix key map."
  "n" my-prefix-note-map
  "d" my-prefix-dotfile-map
  "m" (lambda () (interactive) (man (format "3 %s" (thing-at-point 'word t))))
  "o" #'find-file-at-point
  "v" #'project-recompile
  ;; "l" obs l is reseved for local-only config
  "i" #'my/open-in-intellij
  "b" #'my/switch-to-bb-playground
  "SPC" #'agent-shell)

(which-key-add-keymap-based-replacements my-prefix-map
  "n" `("note" . ,my-prefix-note-map)
  "d" `("dotfiles" . ,my-prefix-dotfile-map))

(keymap-set global-map "C-c" my-prefix-map)

;;; Custom functions

(defun my/pop-to-special-buffer (arg)
  "Pop to special buffer based on prefix argument."
  (interactive "P")
  (if (null arg)
      (progn ;; this extra stuff is only needed for iflipb to call in elisp, if i change cmd can only use cmd then
	(iflipb-next-buffer nil)
	(setq this-command 'iflipb-next-buffer))
    (let* ((arg (prefix-numeric-value arg))
	   (selector
            (pcase arg
	      (1 "\\*Man.*\\*")
	      (2 'agent-shell-mode)
              (3 "\\*compilation\\*")
              (4 "\\*.*eshell\\*")
              (5 "\\*gud-.*\\*")    
              (_ (user-error "Invalid prefix: use 1-5"))))
           (matching-buffers
            (seq-filter (lambda (buf)
			  (if (symbolp selector)
			      (eq (buffer-local-value 'major-mode buf) selector)
			    (string-match-p selector (buffer-name buf))))
			(buffer-list))))
      (cond
       ((null matching-buffers)
	(message "No buffers matching %s" selector))
       ((= 1 (length matching-buffers))
	(pop-to-buffer (car matching-buffers)))
       (t
	(pop-to-buffer
	 (get-buffer
          (completing-read "Select buffer: "
			   (mapcar #'buffer-name matching-buffers)
			   nil t))))))))
;;; Window layout

(dolist (pattern '("\\*compilation\\*"
                   "\\*.*eshell\\*"
                   "\\*Man.*\\*"
		   "\\*eldoc.*\\*"		   
                   "\\*gud-.*\\*"))
  (add-to-list 'display-buffer-alist
	       `(,pattern
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.4)
                 (preserve-size . (nil . t))
                 (window-parameters . ((no-delete-other-windows . t))))))

;; agent-shell match by mode
(add-to-list 'display-buffer-alist
	     `((derived-mode . agent-shell-mode)
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.4)
               (preserve-size . (nil . t))
               (window-parameters . ((no-delete-other-windows . t)))))

;;; Java
(use-package dumb-jump
  :ensure t
  :hook (java-mode . (lambda ()
		       (add-hook 'xref-backend-functions #'dumb-jump-xref-activate nil t))))

(defun my/open-in-intellij ()
  "Open current file at point in an IDE selected from project root markers."
  (interactive)
  (let* ((file (buffer-file-name))
	 (line (number-to-string (line-number-at-pos)))
	 (col (number-to-string (current-column)))
	 (project (project-current nil))
	 (root (and project (project-root project)))
	 (has-pom (and root (file-exists-p (expand-file-name "pom.xml" root))))
	 (has-cargo (and root (file-exists-p (expand-file-name "Cargo.toml" root))))
	 (ide (cond (has-pom "idea")
		    (has-cargo "rustrover")
		    (t (completing-read "Open with: "
					'("idea" "rustrover")
					nil t nil nil "idea")))))
    (if file
	(start-process "open-in-ide" nil ide "--line" line "--column" col file)
      (user-error "Buffer is not visiting a file"))))

;;; Clojure
;; override from local_only using
;; (setq my/bb-playground-initial-content
;;       (concat
;;        ";; Local Babashka Playground\n\n"
;;        "(ns my.scratch)\n"
;;        "(println :hello)\n"))
(defvar my/bb-playground-initial-content
  (concat
   ";; Babashka Playground\n\n"
   "(ns bb-malli\n  (:require [babashka.deps :as deps]))\n"
   "(deps/add-deps '{:deps {metosin/malli {:mvn/version \"0.9.0\"}}})\n"
   "(require '[malli.core :as malli])\n\n"
   ";; Your code here\n")
  "Default content inserted into *bb-playground*.")
(use-package cider
  :ensure t
  :defer nil
  :if (or (executable-find "clj") (executable-find "bb"))
  :config
  (when (executable-find "bb")
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
					    (insert my/bb-playground-initial-content)
					    (goto-char (point-max)) ; Move cursor to end
                                            (sesman-link-with-buffer playground-buffer '("babashka")))
					  (switch-to-buffer playground-buffer)))))))))
    (defun my/switch-to-bb-playground ()
      "Switch to *bb-playground* buffer if it exists, otherwise start babashka REPL and switch to playground."
      (interactive)
      (if (get-buffer "*bb-playground*")
	  (switch-to-buffer "*bb-playground*")
	(my/cider-jack-in-babashka))))
  (setq cider-repl-pop-to-buffer-on-connect nil))

;;; Rust
(use-package rust-ts-mode
  :ensure nil
  :mode ("\\.rs\\'" . rust-ts-mode)
  :hook
  (rust-ts-mode . eglot-ensure)
  :config
  (add-hook 'rust-ts-mode-hook
            (lambda ()
	      ;; Only enable eglot formatting if there is a Cargo.toml found in the project
	      (when (locate-dominating-file default-directory "Cargo.toml")
		(apheleia-mode -1)  ; disable Apheleia did not get rustfmt to work
		(add-hook 'before-save-hook #'eglot-format-buffer nil t))))
  (add-to-list 'treesit-language-source-alist
	       '(rust "https://github.com/tree-sitter/tree-sitter-rust")))

;; Load local_only config if present important this comes last so i can override
;; Patterns to use in extensions
;; build modes extending tabulated-list-mode with trasient menues for each mode kubed is a good example module
;; for quick access to devops command use a alist of command populating completing-read
;; then execute command with (compilation-start <cmd> t) this will support sudo and ansi output via comint mode
;; extend the compilation buffer in all good ways
(let ((local-dir (expand-file-name "local_only" user-emacs-directory)))
  (when (file-directory-p local-dir)
    (add-to-list 'load-path local-dir)
    (load (expand-file-name "init-local" local-dir) t)))
