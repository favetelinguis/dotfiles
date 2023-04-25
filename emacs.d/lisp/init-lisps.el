;; For clojure
(straight-use-package 'clojure-mode)
(straight-use-package 'cider)
;; Enable subword mode in cider repl
(with-eval-after-load 'cider
  (add-hook 'cider-repl-mode-hook 'subword-mode))

;; For scheme
(straight-use-package 'geiser)
(straight-use-package 'geiser-guile)

;; Setup smartparens everywhere
(straight-use-package 'smartparens)
(smartparens-global-strict-mode t)
(sp-pair "'" nil :actions :rem) ; dont create pairs for ' since it makes list hard in elisp
(sp-pair "`" nil :actions :rem)
(setq sp-highlight-pair-overlay nil)

;; Navigate inside
(global-set-key (kbd "C-M-a") 'sp-beginning-of-sexp)
(global-set-key (kbd "C-M-e") 'sp-end-of-sexp)
(global-set-key (kbd "C-M-d") 'sp-down-sexp)
(global-set-key (kbd "C-M-i") 'sp-up-sexp)
(global-set-key (kbd "C-M-u") 'sp-backward-up-sexp)
(global-set-key (kbd "C-M-c") 'sp-backward-down-sexp)
(global-set-key (kbd "C-M-f") 'sp-forward-sexp)
(global-set-key (kbd "C-M-b") 'sp-backward-sexp)
(global-set-key (kbd "M-f") 'sp-forward-symbol)
(global-set-key (kbd "M-b") 'sp-backward-symbol)

;; Navigation top level
(global-set-key (kbd "C-M-n") 'sp-next-sexp)
(global-set-key (kbd "C-M-p") 'sp-previous-sexp)

;; Surround
;; C-M-SPC set region then type (, {, ", ', *, _, etc
(global-set-key (kbd "C-M-<backspace>") 'sp-unwrap-sexp) ; unwrap forward

;; Slurp and barf
(global-set-key (kbd "C-)") 'sp-forward-slurp-sexp)
(global-set-key (kbd "C-(") 'sp-forward-slurp-sexp)
(global-set-key (kbd "C-M-)") 'sp-forward-barf-sexp)
(global-set-key (kbd "C-M-(") 'sp-backward-barf-sexp)

;; Killing/Copy
(global-set-key (kbd "C-M-k") 'sp-kill-sexp)
(global-set-key (kbd "C-M-w") 'sp-copy-sexp)

;; Transpose/Join/Split
(global-set-key (kbd "C-M-t") 'sp-transpose-sexp)
(global-set-key (kbd "C-M-j") 'sp-join-sexp)
(global-set-key (kbd "C-M-s") 'sp-split-sexp)

(provide 'init-lisps)
