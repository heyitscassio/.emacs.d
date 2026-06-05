;; -*- lexical-binding: t; -*-


(defcustom casmacs-default-appearance 'dark
  "Default appearance"
  :type '(choice (const :tag "Dark" dark)
                 (const :tag "Light" light)))

(defcustom casmacs-dark-theme 'leuven-dark
  "My dark theme"
  :type 'symbol)

(defcustom casmacs-light-theme 'leuven-light
  "My light theme"
  :type 'symbol)

(defun casmacs--get-appearance ()
  (if (fboundp 'mac-application-state)
      (if (string= (plist-get (mac-application-state) :appearance)
                   "NSAppearanceNameAqua")
          'light
        'dark)
    casmacs-default-appearance))

(defun casmacs-apply-theme (&optional appearance)
  "Load theme, taking current system APPEARANCE into consideration."
  (let* ((appearance (or appearance (casmacs--get-appearance)))
         (theme (if (eq appearance 'light) casmacs-light-theme casmacs-dark-theme)))
    (dolist (enabled-theme custom-enabled-themes)
      (disable-theme enabled-theme))
    (load-theme theme t)))

(cond
 ((boundp 'ns-system-appearance-change-functions)
  (add-hook 'ns-system-appearance-change-functions #'casmacs-apply-theme))
 ((boundp 'mac-effective-appearance-change-hook)
  (add-hook 'mac-effective-appearance-change-hook #'casmacs-apply-theme)))

(use-package modus-themes
  :custom
  (modus-themes-italic-constructs t)
  (modus-themes-bold-constructs t)
  (modus-themes-org-blocks 'gray-background)
  (casmacs-dark-theme 'modus-vivendi)
  (casmacs-light-theme 'modus-operandi)
  (casmacs-default-appearance 'light)
  :init
  (let ((modus-palette '((fringe                  bg-dim)
                         (bg-mode-line-active     bg-blue-subtle)
                         (fg-mode-line-active     fg-main)
                         (border-mode-line-active blue-intense)
                         ;; (bg-completion bg-inactive)
                         )))
    (setq modus-themes-common-palette-overrides modus-palette))
  (casmacs-apply-theme))

;; (use-package ef-themes
;;   :init
;;   (load-theme 'ef-dark t))

(provide 'cas-emacs-theme)
