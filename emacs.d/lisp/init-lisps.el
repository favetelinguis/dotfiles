(straight-use-package 'clojure-mode)
(straight-use-package 'cider)

(straight-use-package 'paredit)
(add-hook 'emacs-lisp-mode-hook 'paredit-mode)
(add-hook 'clojure-mode-hook 'paredit-mode)
(with-eval-after-load 'cider
  (add-hook 'cider-repl-mode-hook 'subword-mode))

(provide 'init-lisps)
