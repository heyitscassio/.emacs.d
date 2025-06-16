;; -*- lexical-binding: t; -*-


(defcustom casmacs-dark-theme 'leuven-dark
  "My dark theme"
  :type 'symbol)

(defcustom casmacs-light-theme 'leuven-light
  "My light theme"
  :type 'symbol)

(defun casmacs-get-appearance ()
  (if (string= (plist-get (mac-application-state) :appearance) "NSAppearanceNameAqua")
      'light
    'dark))

(defun casmacs-set-theme (appearance)
  (let ((theme (if (eq appearance 'light) casmacs-light-theme casmacs-dark-theme)))
    (dolist (enabled-theme custom-enabled-themes)
      (disable-theme enabled-theme))
    (load-theme theme t)))

(defun casmacs-apply-theme (&optional appearance)
  "Load theme, taking current system APPEARANCE into consideration."
  (mapc #'disable-theme custom-enabled-themes)
  (pcase (or appearance (casmacs-get-appearance))
    ('light (load-theme casmacs-light-theme t))
    ('dark (load-theme casmacs-dark-theme t))))

(add-hook 'mac-effective-appearance-change-hook #'casmacs-apply-theme)

(use-package modus-themes
  :custom
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-org-blocks 'gray-background)
  (casmacs-dark-theme 'modus-vivendi)
  (casmacs-light-theme 'modus-operandi)
  :config
  (let ((modus-palette '((fringe                  bg-dim)
                         (bg-mode-line-active     bg-blue-subtle)
                         (fg-mode-line-active     fg-main)
                         (border-mode-line-active blue-intense)
                         (bg-completion bg-inactive))))
    (setq modus-themes-common-palette-overrides nil
          ;; modus-themes-completions ((matches . ()))
          )
    )
  (load-theme casmacs-dark-theme t))

(provide 'cas-emacs-theme)
