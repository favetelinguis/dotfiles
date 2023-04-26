;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
(setq debug-on-error t)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; Adjust garbage collection thresholds during startup, and thereafter
(setq gc-cons-threshold (* 128 1024 1024))
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold(* 20 1024 1024))))

(require 'init-basic-ux)
(require 'init-package-manager)

;; Start load config for features and modes
(require 'init-minibuffer)
(require 'init-git)
(require 'init-yequake)
(require 'init-chatgpt)
(require 'init-org)
(require 'init-lisps)
(require 'init-yaml)
(require 'init-eshell)
(require 'init-lsp)
(require 'init-programming)
;; End load config for features and modes

;; Allow access from emacsclient
(add-hook 'after-init-hook
          (lambda ()
            (require 'server)
            (unless (server-running-p)
              (server-start))))

(provide 'init)
