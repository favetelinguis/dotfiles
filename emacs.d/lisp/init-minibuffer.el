;; Nicer UI for minibuffer search
(straight-use-package 'vertico)
(add-hook 'after-init-hook 'vertico-mode)

;; Persist history over Emacs restarts. Vertico sorts by history position.
(straight-use-package 'savehist)
(add-hook 'after-init-hook 'savehist-mode)

;; Add additional information to search results in the minibuffer
(straight-use-package 'marginalia)
(add-hook 'after-init-hook 'marginalia-mode)

;; Better matching of search terms
(straight-use-package 'orderless)
(setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion))))


;; Enable indentation+completion using the TAB key.
;; `completion-at-point' is often bound to M-TAB.
(setq tab-always-indent 'complete)
;; Nicer UI for buffer completion
(straight-use-package 'corfu)

;; Enable auto completion and configure quitting
(setq corfu-auto t
corfu-quit-no-match 'separator) ; or t
(add-hook 'after-init-hook 'global-corfu-mode)
;; Make autocomplete more conservative
(with-eval-after-load 'eshell
(add-hook 'eshell-mode-hook
	  (lambda ()
	    (setq-local corfu-auto nil)
	    (corfu-mode))))

;; Prevents us from having to press enter two time on completions
(defun corfu-send-shell (&rest _)
  "Send completion candidate when inside comint/eshell."
  (cond
   ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
    (eshell-send-input))
   ((and (derived-mode-p 'comint-mode)  (fboundp 'comint-send-input))
    (comint-send-input))))

(advice-add #'corfu-insert :after #'corfu-send-shell)

(provide 'init-minibuffer)
