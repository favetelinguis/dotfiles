;; Autosave every 5 seconds to the same file, dont create backupfiles
(auto-save-visited-mode 1)

;; Handle backupfile outside projects directory
(setq backup-directory-alist '(("." . "~/.emacs.d/backup"))
backup-by-copying t    ; Don't delink hardlinks
version-control t      ; Use version numbers on backups
delete-old-versions t  ; Automatically delete excess backups
kept-new-versions 20   ; how many of the newest versions to keep
kept-old-versions 5    ; and how many of the old
)

;; Allow all disabled comands as default, for example a in dired
(setq disabled-command-function nil)


;; Cleanup Emacs user interface
(setq inhibit-startup-message t)

(scroll-bar-mode -1) ; Disable visible scrollbar
(tool-bar-mode -1)  ; Disable the toolbar
(tooltip-mode -1) ; Disable tooltips
(set-fringe-mode 10)
(menu-bar-mode -1) ; Disable the menu bar
(setq visible-bell t) ; Turn off sound and show flashing warning instead

(set-face-attribute 'default nil :family "Fira Code" :height 140 :weight 'normal)

(provide 'init-basic-ux)
