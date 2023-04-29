;; Jumping between buffers easy
(global-set-key (kbd "C-'") 'previous-buffer)
(global-set-key (kbd "C-M-'") 'next-buffer)

;; Filter Select Act
(straight-use-package 'ace-window)
(global-set-key (kbd "M-o") 'ace-window)

;; Avy to use with isearch
(straight-use-package 'avy)
(define-key isearch-mode-map (kbd "C-;") 'avy-isearch)

;; Act on things with embark
(straight-use-package 'embark)
(global-set-key (kbd "C-;") 'embark-act)

;; Access all embark commands from avy
(defun avy-action-embark (pt)
  (unwind-protect
      (save-excursion
        (goto-char pt)
        (embark-act))
    (select-window
     (cdr (ring-ref avy-ring 0))))
  t)
(require 'avy)
(setf (alist-get ?\; avy-dispatch-alist) 'avy-action-embark)

;; Required by consult for some things
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;; Add better variant for some search commands
;; Consult only setup commands, no modes or key bindings as default
(straight-use-package 'consult)
(straight-use-package 'embark-consult)
(global-set-key (kbd "M-i") 'consult-imenu)
(global-set-key (kbd "M-I") 'consult-imenu-multi)

;; Setup prjectile with consult and embark
(straight-use-package 'projectile)
(projectile-mode +1)
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
(when (file-directory-p "~/repos")
      (setq projectile-project-search-path '(("~/repos" . 2))))
(straight-use-package 'consult-projectile)
(global-set-key (kbd "M-j") 'consult-buffer)
(global-set-key (kbd "M-J") 'consult-projectile)

(defun embark-magit-status (path)
  "Run `magit-status` on repo containing the embark target."
  (interactive "GPath: ")
  (magit-status path))

(defun embark-consult-ripgrep (path)
  "Run consult-ripgrep in project root."
  (interactive "GPath: ")
  (consult-ripgrep path))

;; Copy of projectile-run-eshell but I overriede the default project root
(defun embark-eshell (path)
  "Launch eshell from project root"
  (interactive "GPath: ")
  (let ((projectile-project-root path))
    (projectile-run-eshell)))

(require 'compat-29)
(require 'embark)
(defvar-keymap embark-projectile-map
  :doc "Keymap for Embark projectile actions."
  :parent embark-general-map
  "v" 'embark-magit-status
  "d" 'dired
  "s" 'embark-eshell
  "g" 'embark-consult-ripgrep)
(add-to-list 'embark-keymap-alist '(consult-projectile-project . embark-projectile-map))

;; Integrate ace-window with embark works with 2 or more windows
;; taken from https://karthinks.com/software/fifteen-ways-to-use-embark/
(eval-when-compile
  (defmacro my/embark-ace-action (fn)
    `(defun ,(intern (concat "my/embark-ace-" (symbol-name fn))) ()
       (interactive)
       (with-demoted-errors "%s"
         (require 'ace-window)
         (let ((aw-dispatch-always t))
           (aw-switch-to-window (aw-select nil))
           (call-interactively (symbol-function ',fn)))))))

(define-key embark-file-map     (kbd "o") (my/embark-ace-action find-file))
(define-key embark-buffer-map   (kbd "o") (my/embark-ace-action switch-to-buffer))
(define-key embark-bookmark-map (kbd "o") (my/embark-ace-action bookmark-jump))

;; I dont want to use ace-window when we only have one window, then i can use splitting of that one window
(eval-when-compile
  (defmacro my/embark-split-action (fn split-type)
    `(defun ,(intern (concat "my/embark-"
                             (symbol-name fn)
                             "-"
                             (car (last  (split-string
                                          (symbol-name split-type) "-"))))) ()
       (interactive)
       (funcall #',split-type)
       (call-interactively #',fn))))

(define-key embark-file-map     (kbd "2") (my/embark-split-action find-file split-window-below))
(define-key embark-buffer-map   (kbd "2") (my/embark-split-action switch-to-buffer split-window-below))
(define-key embark-bookmark-map (kbd "2") (my/embark-split-action bookmark-jump split-window-below))

(define-key embark-file-map     (kbd "3") (my/embark-split-action find-file split-window-right))
(define-key embark-buffer-map   (kbd "3") (my/embark-split-action switch-to-buffer split-window-right))
(define-key embark-bookmark-map (kbd "3") (my/embark-split-action bookmark-jump split-window-right))

;; Some consult overrides
(global-set-key (kbd "M-y") 'consult-yank-from-kill-ring)
(define-key projectile-command-map (kbd "g") 'consult-ripgrep)
(setq xref-show-xrefs-function #'consult-xref
      xref-show-xrefs #'consult-xref)

;; Optionally configure the register formatting. This improves the register
;; preview for `consult-register', `consult-register-load',
;; `consult-register-store' and the Emacs built-ins.
(setq register-preview-delay 0.5
      register-preview-function #'consult-register-format)

;; Optionally tweak the register preview window.
;; This adds thin lines, sorting and hides the mode line of the window.
(advice-add #'register-preview :override #'consult-register-window)

;; Custom binding for easier register access
(global-set-key (kbd "C-x r v") 'view-register)

(provide 'init-navigation)
