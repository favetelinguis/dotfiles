;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/") ;; Get latest org mode
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
   (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t) ; Install packages if they are not avaliable already
;; (setq use-package-verbose t) ; uncomment for debugging config, prints more to messages buffer
; To update the package list use M-x list-packages this can be good if i get error trying to instal new packages
; C-h f function v variable k keybinding h general help

(use-package gcmh
:ensure t
:demand t
:config
(gcmh-mode 1))

;; Cleanup Emacs user interface
(setq inhibit-startup-message t)

(scroll-bar-mode -1) ; Disable visible scrollbar
(tool-bar-mode -1)  ; Disable the toolbar
(tooltip-mode -1) ; Disable tooltips
(set-fringe-mode 10)
(menu-bar-mode -1) ; Disable the menu bar
(setq visible-bell t) ; Turn off sound and show flashing warning instead

(set-face-attribute 'default nil :family "Fira Code" :height 140 :weight 'normal)

(load-theme 'tango-dark)

(auto-save-visited-mode 1)

(setq backup-directory-alist '(("." . "~/.emacs.d/backup"))
backup-by-copying t    ; Don't delink hardlinks
version-control t      ; Use version numbers on backups
delete-old-versions t  ; Automatically delete excess backups
kept-new-versions 20   ; how many of the newest versions to keep
kept-old-versions 5    ; and how many of the old
)

(use-package which-key
  :defer 0
  :diminish which-key-mode
  :config
  (which-key-mode)
  (setq which-key-idle-delay 1))

; Using M-o while inside a ivy buffer shows any special things one can do in that buffer
; Using C-c C-o persist an ivy search buffer for example with ripgrep
(use-package counsel
  :bind (:map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)	
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :init (ivy-mode 1))

; Serch projects p search f search files sr search using rg xe eshell q switch between open projects
; Depends of fd and ripgrep
; Add shortcut to open projet in idea
(use-package projectile
  :custom ((projectile-completion-system 'ivy))
  :bind ("M-SPC" . projectile-commander)
;  :bind-keymap
;  ("C-c p" . projectile-command-map)
  :config
  (projectile-mode)
(def-projectile-commander-method ?s
  "Open a *shell* buffer for the project."
  (projectile-run-eshell))

(def-projectile-commander-method ?c
  "Run `compile' in the project."
  (projectile-compile-project nil))

(def-projectile-commander-method ?p
  "Project selection."
  (projectile-switch-project))

(def-projectile-commander-method ?d
  "Open project root in dired."
  (projectile-dired))

(def-projectile-commander-method ?j
  "Jump to project buffer."
  (projectile-switch-to-buffer))

(def-projectile-commander-method ?/
  "rg project"
  (counsel-rg))
  ;; NOTE: Set this to the folder where you keep your Git repos!
;  (setq projectile-create-missing-test-files t)
  :init
  (when (file-directory-p "~/repos")
    (setq projectile-project-search-path '(("~/repos" . 2))))
  (setq projectile-switch-project-action #'projectile-commander)
  )

(use-package lispy)
(add-hook 'emacs-lisp-mode-hook (lambda () (lispy-mode 1)))
(add-hook 'clojure-mode-hook (lambda () (lispy-mode 1)))

(add-hook 'emacs-lisp-mode-hook 'flymake-mode)

(setq flymake-log-level 'warning)

(use-package clojure-mode)
(use-package cider)

(use-package yaml-mode)

(use-package magit
     :custom
     (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  )

  (use-package forge
    :after magit)
(setq auth-sources '("~/.authinfo")) ; Set where api key is stored for forge, check dock for format

(defun fav/org-mode-setup ()
	(visual-line-mode 1) ; Make text wrap when at the end of window
)
    (use-package org
      :custom ; dont use setq in config use custom instead!
      (org-agenda-files '("~/roam-notes/"))
      (org-confirm-babel-evaluate nil) ; dont have to confirm each execute block
      (org-agenda-start-with-log-mode t)
      (org-log-done 'time)
(org-agenda-span 'day)
      :hook (org-mode . fav/org-mode-setup)
      :bind
      (("M-'" . org-agenda)
       ("C-M-'" . counsel-org-agenda-headlines))
      :config
      (require 'org-tempo)
     (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
      (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp")) ; <el <TAB>
      )

(use-package org-roam
	      :custom
	    (org-roam-directory "~/roam-notes")
  (org-roam-completion-everywhere t)
	  :bind
(("C-c n l" . org-roam-buffer-toggle)
	("C-c n f" . org-roam-node-find)
	("C-'" . org-roam-node-find)
      ("C-c n i" . org-roam-node-insert))
    :config
  (org-roam-setup))

; C-c C-c eval block of code
(org-babel-do-load-languages 'org-babel-load-languages
			     '((emacs-lisp . t)))

(use-package simple-httpd)

(use-package dired
  :ensure nil
  :bind (("C--" . dired-jump)))

(defun fav/configure-eshell ()
  ;; Save command history when commands are entered
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

  ;; Truncate buffer for performance
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

  (setq eshell-history-size         10000
	eshell-buffer-maximum-lines 10000
	eshell-hist-ignoredups t ; dont put consecutive commands in history
	eshell-scroll-to-bottom-on-input t))

(use-package eshell
  :hook (eshell-first-time-mode . fav/configure-eshell)
:custom (eshell-banner-message "")
  :config

  (with-eval-after-load 'esh-opt
    (setq eshell-destroy-buffer-when-process-dies t)
    (setq eshell-visual-commands '("htop" "zsh" "vim")))
  )

   (add-hook 'emacs-startup-hook #'eshell)

(global-set-key (kbd "C-x k") 'kill-this-buffer)

(defun fav/read-openai-key ()
  (with-temp-buffer
    (insert-file-contents "~/key.txt")
    (string-trim (buffer-string))))

(use-package gptel
  :init
  (setq-default gptel-model "gpt-3.5-turbo"
                gptel-playback t
                gptel-default-mode 'org-mode
                gptel-api-key #'fav/read-openai-key))

(when (file-exists-p "~/.emacs.d/custom-packages/custom.el")
 (add-to-list 'load-path "~/.emacs.d/custom-packages")
 (require 'my-custom))

(use-package company
  :init
  (add-hook 'after-init-hook 'global-company-mode))

(global-set-key (kbd "C-\\") 'company-complete)

(use-package avy
  :init
  (avy-setup-default)
  (global-set-key (kbd "C-;") 'avy-goto-char-timer))
