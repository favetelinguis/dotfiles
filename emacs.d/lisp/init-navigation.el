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
(setf (alist-get ?. avy-dispatch-alist) 'avy-action-embark)

;; Required by consult for some things
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;; Add better variant for some search commands
;; Consult only setup commands, no modes or key bindings as default
(straight-use-package 'consult)
(straight-use-package 'embark-consult)
(global-set-key (kbd "M-j") 'consult-buffer)
(global-set-key (kbd "M-i") 'consult-imenu)

;; Make project.el search buffer
(straight-use-package 'consult-project-extra)
(global-set-key (kbd "M-J") 'consult-project-extra-find)

(provide 'init-navigation)
