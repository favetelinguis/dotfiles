;; For clojure
(straight-use-package 'clojure-mode)
(straight-use-package 'cider)
;; Enable subword mode in cider repl
(with-eval-after-load 'cider
  (add-hook 'cider-repl-mode-hook 'subword-mode))

;; For scheme
(straight-use-package 'geiser)
(straight-use-package 'geiser-guile)

;; Setup paredit for lisp
(straight-use-package 'paredit)
(add-hook 'emacs-lisp-mode-hook 'paredit-mode)
(add-hook 'clojure-mode-hook 'paredit-mode)
(add-hook 'geiser-mode-hook 'paredit-mode)

(provide 'init-lisps)
