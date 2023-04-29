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

(define-key embark-file-map     (kbd "O") (my/embark-ace-action find-file))
(define-key embark-buffer-map   (kbd "O") (my/embark-ace-action switch-to-buffer))
(define-key embark-bookmark-map (kbd "O") (my/embark-ace-action bookmark-jump))

(provide 'init-navigation)
