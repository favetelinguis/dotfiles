;;; -*- lexical-binding: t -*-

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

(use-package emacs
  :config
  ;;; Prevent Extraneous Tabs
  (setq-default indent-tabs-mode nil)
  ;; Dont write custom data into init.el
  (setq custom-file (concat user-emacs-directory "custom.el"))
  (setq custom-file "~/.emacs.d/custom.el")
  
  ;; Remove auto-saved filed when buffer is killed
  ;; default is to remove it when its saved only.
  (setq kill-buffer-delete-auto-save-files t)

  ;; Turn on relative line numbers
  ;;(global-display-line-numbers-mode 1)
  ;;(setq display-line-numbers-type 'relative)

  ;; Handle backupfile outside projects directory
  (setq backup-directory-alist '(("." . "~/.emacs.d/backup"))
	backup-by-copying t    ; Don't delink hardlinks
	version-control t      ; Use version numbers on backups
	delete-old-versions t  ; Automatically delete excess backups
	kept-new-versions 20   ; how many of the newest versions to keep
	kept-old-versions 5    ; and how many of the old
	)

  ;; Allow all disabled comands as default, for example a in dired
  (setq disabled-command-function nil)


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
  ;; Unbind useless things to make meow leader better
  (global-unset-key (kbd "C-x C-0"))
  (global-unset-key (kbd "C-x C-v"))
  (global-unset-key (kbd "C-h C-f"))
  (global-unset-key (kbd "C-h C-m"))
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

(use-package dired
  :straight nil
  :config
  (setf dired-kill-when-opening-new-dired-buffer t))

(use-package ibuffer
  :config
  (global-set-key (kbd "C-x C-b") 'ibuffer))

(use-package avy
  :preface
  (defun my/jumper (&optional arg)
    (interactive)
    (if (region-active-p)
	(meow-search arg)
      (avy-goto-char-timer)))
  :config
  (setq avy-timeout-seconds 0.4))

(use-package meow
  :after avy
  :preface
  (defun meow-setup ()
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    (meow-motion-overwrite-define-key
     '("n" . meow-next)
     '("p" . meow-prev)
     '("<escape>" . ignore))
    (meow-leader-define-key
     ;; SPC j/k will run the original command in MOTION state.
     '("n" . "H-n")
     '("p" . "H-p")
     ;; Use SPC (0-9) for digit arguments.
     '("1" . meow-digit-argument)
     '("2" . meow-digit-argument)
     '("3" . meow-digit-argument)
     '("4" . meow-digit-argument)
     '("5" . meow-digit-argument)
     '("6" . meow-digit-argument)
     '("7" . meow-digit-argument)
     '("8" . meow-digit-argument)
     '("9" . meow-digit-argument)
     '("0" . meow-digit-argument)
     '("/" . meow-keypad-describe-key)
     '("?" . meow-cheatsheet))
    (meow-normal-define-key
     '("0" . meow-expand-0)
     '("9" . meow-expand-9)
     '("8" . meow-expand-8)
     '("7" . meow-expand-7)
     '("6" . meow-expand-6)
     '("5" . meow-expand-5)
     '("4" . meow-expand-4)
     '("3" . meow-expand-3)
     '("2" . meow-expand-2)
     '("1" . meow-expand-1)
     '("-" . negative-argument)
     '(";" . meow-reverse)
     '("," . meow-inner-of-thing)
     '("<" . sp-splice-sexp-killing-backward)
     '("." . meow-bounds-of-thing)
     '(">" . sp-forward-slurp-sexp)
     '("[" . meow-beginning-of-thing)
     '("]" . meow-end-of-thing)
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
     '("f" . meow-find)
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
     '("j" . my/jumper)
     '("o" . meow-block)
     '("O" . meow-to-block)
     '("s" . meow-yank)
     '("q" . meow-quit)
     '("Q" . meow-goto-line)
     '("r" . meow-replace)
     '("R" . meow-swap-grab)
     '("k" . meow-kill)
     '("t" . meow-till)
     '("u" . meow-undo)
     '("U" . meow-undo-in-selection)
     '("v" . meow-visit)
     '("w" . meow-mark-word)
     '("W" . meow-mark-symbol)
     '("x" . meow-line)
     '("X" . meow-goto-line)
     '("y" . meow-save)
     '("Y" . meow-sync-grab)
     '("z" . meow-pop-selection)
     '("'" . repeat)
     '("<escape>" . ignore)))
  :config
  (setq meow-cheatsheet-physical-layout meow-cheatsheet-physical-layout-ansi)
  (meow-setup)
  (meow-global-mode 1)
  ;; Auto exit insert mode after x seconds
  (add-hook
   'meow-insert-enter-hook
   (lambda ()
     (setq meow-insert-timer
           (run-with-idle-timer
            3 nil
            (lambda ()
              (when (eq meow--current-state 'insert)
		(meow--switch-state 'normal)))))))

  (add-hook
   'meow-insert-exit-hook
   (lambda ()
     (when (and (bound-and-true-p meow-insert-timer)
		(timerp meow-insert-timer))
       (cancel-timer meow-insert-timer)
       (setq meow-insert-timer nil)))))

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
  :config
  (global-set-key (kbd "C-x C-p") project-prefix-map)
  (project-remember-projects-under "~/repos" t))

(use-package chezmoi)
(use-package chezmoi-dired
  :after chezmoi
  :straight nil
  :load-path "straight/repos/chezmoi.el/extensions/")

(use-package apheleia
  ;; TODO setup for clojure something like this, used in doom
  ;; (set-formatter! 'cljfmt '("cljfmt" "fix" "-") :modes '(clojure-mode clojurec-mode clojurescript-mode))
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

(use-package stimmung-themes
  :straight (stimmung-themes :host github :repo "motform/stimmung-themes")
  :demand t
  :config (stimmung-themes-load-light))

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
  (smartparens-global-mode t)) ; there is also smartparens-mode

(use-package cider)
(use-package clay
  :straight (:host github :repo "scicloj/clay.el"))
(use-package markdown-mode)
;; cider
;; clay
;; investigate what the workflow is for using marks to just to things c-spc will set mark but how to jump to
