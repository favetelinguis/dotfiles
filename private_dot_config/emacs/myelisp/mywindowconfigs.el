;;; mywindowconfigs.el --- Setup all my window configs  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Henrik Larsson

;; Author: Henrik Larsson <henriklarsson@localhost.localdomain>
;; Keywords: lisp

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Based on https://www.masteringemacs.org/article/demystifying-emacs-window-manager

;;; Code:

(add-to-list 'display-buffer-alist
             '("\\*e?shell\\*" display-buffer-in-direction
               (direction . bottom)
               (window . root)
               (window-height . 0.3)))

;; left, top, right, bottom
(setq window-sides-slots '(0 0 1 0))

(add-to-list 'display-buffer-alist
             `(,(rx (| "*compilation*" "*grep*"))
               display-buffer-in-side-window
               (side . right)
               (slot . 0)
               (window-parameters . ((no-delete-other-windows . t)))
               (window-width . 80)))

(add-to-list 'display-buffer-alist
             `("^test[-_]"
               display-buffer-in-direction
               (direction . right)))

(provide 'mywindowconfigs)
;;; mywindowconfigs.el ends here

