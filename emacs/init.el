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
; To update the package list use M-x list-packages this can be good if i get error trying to instal new packages
; C-h f function v variable k keybinding h general help

;; Cleanup Emacs user interface
(setq inhibit-startup-message t)

(scroll-bar-mode -1) ; Disable visible scrollbar
(tool-bar-mode -1)  ; Disable the toolbar
(tooltip-mode -1) ; Disable tooltips
(set-fringe-mode 10)
(menu-bar-mode -1) ; Disable the menu bar
(setq visible-bell t) ; Turn off sound and show flashing warning instead

(set-face-attribute 'default nil :family "Inconsolata" :height 145 :weight 'normal)

(load-theme 'wombat)

; Using M-o while inside a ivy buffer shows any special things one can do in that buffer
; Using C-c C-o persist an ivy search buffer for example with ripgrep
(use-package counsel
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
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

(use-package evil
  :init
  (setq evil-want-keybinding nil)
  (setq evil-want-integration t)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode))

; Serch projects p search f search files sr search using rg xe eshell q switch between open projects
; Depends of fd and ripgrep
; Add shortcut to open projet in idea
(use-package projectile
  :custom ((projectile-completion-system 'ivy))
  :bind ("C-SPC" . projectile-commander)
;  :bind-keymap
;  ("C-c p" . projectile-command-map)
  :config
  (projectile-mode)
(def-projectile-commander-method ?s
  "Open a *shell* buffer for the project."
  (projectile-run-shell))

(def-projectile-commander-method ?c
  "Run `compile' in the project."
  (projectile-compile-project nil))

(def-projectile-commander-method ?p
  "Project selection."
  (projectile-switch-project))

(def-projectile-commander-method ?d
  "Open project root in dired."
  (projectile-dired))

(def-projectile-commander-method ?/
  "rg project"
  (-projectile-rg))
  ;; NOTE: Set this to the folder where you keep your Git repos!
;  (setq projectile-create-missing-test-files t)
  :init
  (when (file-directory-p "~/repos")
    (setq projectile-project-search-path '("~/repos")))
  (setq projectile-switch-project-action #'projectile-commander)
  ;(setq projectile-switch-project-action #'projectile-commander) ; First thing to happen when switching project
  )

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package forge
  :after magit)

(use-package org
  :custom ; dont use setq in config use custom instead!
  ;; (org-agenda-files '("~/orgfiles/tasks.org"))
  (org-confirm-babel-evaluate nil) ; dont have to confirm each execute block
  (org-agenda-start-with-log-mode t)
  (org-log-done 'time)
  (require 'org-tempo)
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp")) ; <el <TAB>
  )

; C-c C-c eval block of code
(org-babel-do-load-languages 'org-babel-load-languages
			     '((emacs-lisp . t)))

; Load extra dired stuff to enable dired-jump
 (add-hook 'dired-load-hook
            (function (lambda () (load "dired-x"))))

(add-hook 'emacs-startup-hook #'eshell)

(defun fav/toggle-buffer ()
  "Flips to the last-visited buffer in this window."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer))))


;; Make killing current buffer faster
(global-set-key (kbd "C-x k") 'kill-this-buffer)

(global-set-key (kbd "C-;") 'fav/toggle-buffer)
(global-set-key (kbd "M-;") 'other-window)

(global-set-key (kbd "C-'") 'org-agenda-list)
(global-set-key (kbd "M-'") 'counsel-org-agenda-headlines) 
(global-set-key (kbd "C-M-'") 'org-agenda) 

(global-set-key (kbd "C--") 'dired-jump) 
;(define-key KEYMAP KEY DEF)
