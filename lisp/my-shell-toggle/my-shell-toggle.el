;;; my-shell-toggle.el --- My shell toggle -*- lexical-binding: t -*-

;;; Code:

(require 'vterm nil t)
(require 'project nil t)

(defvar vterm-buffer-name)

(defun my-shell--get-buffer-name ()
  (if-let ((current (project-current)))
      (format "*shell - %s*" (project-name current))
    "*shell - default*"))

(defun my-shell--get-directory ()
  (if-let ((current (project-current)))
      (project-root (project-current))
    default-directory))

(defun my-shell-toggle ()
  (interactive)
  (let* ((default-directory (my-shell--get-directory))
         (buffer (get-buffer-create (my-shell--get-buffer-name))))
    (if (eq (current-buffer) buffer)
        (quit-window nil)
      (with-current-buffer buffer
        (unless (derived-mode-p 'vterm-mode)
          (vterm-mode))
        (display-buffer-in-side-window buffer nil)
        (pop-to-buffer buffer)))))

(defun my-shell-toggle-full ()
  (interactive)
  (let ((buffer (get-buffer-create (my-shell--get-buffer-name))))
    (with-current-buffer buffer
      (unless (derived-mode-p 'vterm-mode)
        (vterm-mode))
      (if (= 1 (length (window-list)))
          (progn
            (jump-to-register 'my-shel--win)
            (quit-window nil (get-buffer-window buffer)))
        (progn
          (window-configuration-to-register 'my-shel--win)
          (pop-to-buffer buffer)
          (delete-other-windows))))))

;; (add-to-list 'display-buffer-alist
;;              '("\\*shell - .*"
;;                (display-buffer-in-side-window)
;;                (window-height . 0.2)
;;                (preserve-size nil . t)))

(provide 'my-shell-toggle)

;;; my-shell-toggle.el ends here


