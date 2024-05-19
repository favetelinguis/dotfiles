;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;(setq doom-font (font-spec :family "Fira Code" :size 15))
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-homage-white)
(setq doom-theme 'doom-myalabaster)
;; (setq doom-theme 'alabaster)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Setup plantuml with ord-babel
;; The path is use here is where my Arch distrobox installs to
(setq org-plantuml-jar-path
      (expand-file-name "/usr/share/java/plantuml/plantuml.jar"))

;; Need to have this before org or else it is not loaded
(map! :leader "d" #'org-roam-dailies-capture-today)
(after! org
  (map! (:leader (:prefix "n" :desc "consult org agenda" :nv "h" #'consult-org-agenda)))
  (add-to-list 'org-src-lang-modes '("plantuml" . plantuml))
  (org-babel-do-load-languages 'org-babel-do-load-languages '((plantuml . t)))
  (setq org-agenda-start-with-log-mode 't)
  (setq org-log-done 'note)

  (setq org-capture-templates
        '(("t" "Project todo" entry #'+org-capture-central-project-todo-file
           "* TODO %?\n %i\n" :heading "Tasks" :prepend nil)
          ("p" "Personal todo" entry
           (file+headline +org-capture-todo-file "Inbox")
           "* [ ] %?\n%i\n" :prepend t)))
  ;; end
  )

(setq projectile-project-search-path '(("~/repos" . 2)))
(setq projectile-auto-discover 't)

(defun fav/read-openai-key ()
  (with-temp-buffer
    (insert-file-contents "~/key.txt")
    (string-trim (buffer-string))))

(setq-default gptel-model "gpt-3.5-turbo"
              gptel-playback t
              gptel-default-mode 'org-mode
              gptel-api-key #'fav/read-openai-key)
(map! :leader
      (:prefix-map ("k" . "smartparens-mode")
       :desc "sp-forward-slurp-sexp" "s" #'sp-forward-slurp-sexp
       :desc "sp-forward-sexp" "L" #'sp-forward-sexp
       :desc "sp-backward-sexp" "H" #'sp-backward-sexp
       :desc "sp-splice-sexp-killing-backward" "e" #'sp-splice-sexp-killing-backward
       ;; "C-M-u" #'sp-backward-up-sexp
       ;; "C-M-d" #'sp-down-sexp
       ;; "C-M-p" #'sp-backward-down-sexp
       ;; "C-M-n" #'sp-up-sexp
       ;; "C-M-s" #'sp-splice-sexp
       :desc "sp-backward-slurp-sexp" "S" #'sp-backward-slurp-sexp
       :desc "sp-backward-barf-sexp" "B" #'sp-backward-barf-sexp))

(with-eval-after-load 'evil-maps
  (define-key evil-normal-state-map (kbd ";") 'avy-goto-char-timer))

(defun cust/vsplit-file-open (f)
  (let ((evil-vsplit-window-right t))
    (+evil/window-vsplit-and-follow)
    (find-file f)))

(defun cust/split-file-open (f)
  (let ((evil-split-window-below t))
    (+evil/window-split-and-follow)
    (find-file f)))

(map! :after embark
      :map embark-file-map
      "V" #'cust/vsplit-file-open
      "X" #'cust/split-file-open)

(defun fav/open-new-eww ()
  "Will call eww with prefix command which should open a
   new eww and not replace old"
  (interactive)
  (let ((current-prefix-arg '(4))) ; C-u
    (call-interactively 'eww)))

(map! (:leader (:prefix "o" :desc "Open new eww" :nv "w" #'fav/open-new-eww)))

(general-define-key
 :states '(normal)
 :keymaps 'eww-mode-map
 "r" '(eww-reload :which-key "Reload page"))

(setq doom-localleader-key ",")

(defun fav/start-idea ()
  (interactive)
  (projectile-run-async-shell-command-in-root "idea ."))

(map! (:leader (:prefix "p" :desc "Open IDEA" :nv "I" #'fav/start-idea)))

(after! cider
  (use-package! clay)
  (map! :localleader
        :map clojure-mode-map
        :desc "start" "s s" #'clay/start
        :desc "send defun at point" "s d" #'clay/make-defun-at-point
        :desc "send last sexp" "s e" #'clay/make-last-sexp
        :desc "send ns as html" "s h" #'clay/make-ns-html))


(use-package! chezmoi
  :config
  (load "~/.config/emacs/.local/straight/repos/chezmoi.el/extensions/chezmoi-magit.el" nil 'nomessage)
  (load "~/.config/emacs/.local/straight/repos/chezmoi.el/extensions/chezmoi-dired.el" nil 'nomessage))

(use-package chezmoi-magit)
(map! (:leader (:prefix "f" :desc "Chezmoi find" :nv "p" #'chezmoi-find)))
(defun chezmoi--evil-insert-state-enter ()
  "Run after evil-insert-state-entry."
  (chezmoi-template-buffer-display nil (point))
  (remove-hook 'after-change-functions #'chezmoi-template--after-change 1))

(defun chezmoi--evil-insert-state-exit ()
  "Run after evil-insert-state-exit."
  (chezmoi-template-buffer-display nil)
  (chezmoi-template-buffer-display t)
  (add-hook 'after-change-functions #'chezmoi-template--after-change nil 1))

(defun chezmoi-evil ()
  (if chezmoi-mode
      (progn
        (add-hook 'evil-insert-state-entry-hook #'chezmoi--evil-insert-state-enter nil 1)
        (add-hook 'evil-insert-state-exit-hook #'chezmoi--evil-insert-state-exit nil 1))
    (progn
      (remove-hook 'evil-insert-state-entry-hook #'chezmoi--evil-insert-state-enter 1)
      (remove-hook 'evil-insert-state-exit-hook #'chezmoi--evil-insert-state-exit 1))))
(add-hook 'chezmoi-mode-hook #'chezmoi-evil)

(use-package! justl
  :config
  (map! :map justl-mode-map :n "e" 'justl-exec-recipe)
  (with-eval-after-load 'evil-maps
    (define-key evil-normal-state-map (kbd "'") 'justl)))

(use-package! asdf
  :init
  (setq asdf-binary "/opt/asdf-vm/bin/asdf")
  :config
  (asdf-enable))
