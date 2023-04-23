(straight-use-package 'yaml-mode)
;; (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
;; Dont think this is needed (add-to-list 'auto-mode-alist '("\\.yaml\\'" . yaml-mode))
;; Mode dont bind RET to newline and indent by default
;; (add-hook 'yaml-mode-hook
;; 	  '(lambda ()
;; 	     (define-key yaml-mode-map "\C-m" 'newline-and-indent)))

(provide 'init-yaml)
