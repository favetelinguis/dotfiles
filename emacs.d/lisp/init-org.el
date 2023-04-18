(defun fav/org-mode-setup ()
  (visual-line-mode 1)) ; Make text wrap when at the end of window

(straight-use-package 'org)
(setq org-agenda-files '("~/roam-notes/"))
(setq org-confirm-babel-evaluate nil) ; dont have to confirm each execute block
(setq org-agenda-start-with-log-mode t)
(setq org-log-done 'time)
(setq org-agenda-span 'day)
(add-hook 'org-mode-hook 'fav/org-mode-setup)
(global-set-key (kbd "M-'") 'org-agenda)
(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))

;; Setup org-roam
(straight-use-package 'org-roam)
(setq org-roam-directory "~/roam-notes")
(setq org-roam-completion-everywhere t)
(global-set-key (kbd "C-c n l") 'org-roam-buffer-toggle)
(global-set-key (kbd "C-c n f") 'org-roam-node-find)
(global-set-key (kbd "C-'") 'org-roam-node-find)
(global-set-key (kbd "C-c n i") 'org-roam-node-insert)

(provide 'init-org)
