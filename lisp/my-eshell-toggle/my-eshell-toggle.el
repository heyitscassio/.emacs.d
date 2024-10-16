;;; my-eshell-toggle.el --- My eshell toggle -*- lexical-binding: t -*-

;;; Code:

(defvar default-directory)

(defvar eshell-buffer-name)

(defun my-eshell--get-buffer-name ()
  (if-let ((current (project-current)))
      (format "*eshell - %s*" (project-name current))
    "*eshell - default*"))

(defun my-eshell--get-directory ()
  (if-let ((current (project-current)))
      (project-root (project-current))
    default-directory))

(defun my-eshell-toggle ()
  (interactive)
  (let ((default-directory (my-eshell--get-directory))
        (eshell-buffer-name (my-eshell--get-buffer-name)))
    (if (string= (buffer-name) eshell-buffer-name)
        (quit-window)
      (eshell))))

(provide 'my-eshell-toggle)

;;; my-eshell-toggle.el ends here
