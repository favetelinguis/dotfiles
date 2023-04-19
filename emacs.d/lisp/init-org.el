;; Make sure to run  M-x org-roam-db-sync

(defun fav/org-mode-setup ()
  (visual-line-mode 1)) ; Make text wrap when at the end of window

(straight-use-package 'org)
(setq org-agenda-files '("~/roam-notes/"))
(setq org-confirm-babel-evaluate nil) ; dont have to confirm each execute block
(setq org-agenda-start-with-log-mode t)
(setq org-log-done 'time)
(setq org-agenda-span 'day)
(add-hook 'org-mode-hook 'fav/org-mode-setup)
(global-set-key (kbd "C-c n a") 'org-agenda)
(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))

(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

;; Setup org-roam
(straight-use-package 'org-roam)
(setq org-roam-directory "~/roam-notes")
(setq org-roam-completion-everywhere t)
(global-set-key (kbd "C-c n l") 'org-roam-buffer-toggle)
(global-set-key (kbd "C-c n f") 'org-roam-node-find)
(global-set-key (kbd "C-c n n") 'org-roam-capture)
(global-set-key (kbd "C-c n i") 'org-roam-node-insert-immediate)
(global-set-key (kbd "C-c n I") 'org-roam-node-insert)

(require 'org-roam-dailies)
;; Prefix key for all dailies commands
(global-set-key (kbd "C-c n d") 'org-roam-dailies-map)
(define-key org-roam-dailies-map (kbd "Y") 'org-roam-dailies-capture-yesterday)
(define-key org-roam-dailies-map (kbd "T") 'org-roam-dailies-capture-tomorrow)

(provide 'init-org)
