;; -*- lexical-binding: t; -*-

(use-package undo-fu
  :custom
  (undo-limit 1600000))

(use-package undo-fu-session
  :init
  (undo-fu-session-global-mode))

(use-package vundo
  :custom
  (vundo-window-max-height nil)
  (vundo-roll-back-on-quit nil)
  :init
  (add-to-list 'display-buffer-alist
               '(" \\*vundo tree\\*"
                 (display-buffer-at-bottom)
                 (side . bottom)
                 (slot . 0)
                 (window-height . .33))))

(use-package evil
  :hook (emacs-lisp-mode . (lambda () (setq evil-lookup-func #'casmacs-elisp-lookup)))
  :general
  (:keymaps 'evil-window-map
   "C-w" #'other-window)
  :custom
  (evil-want-Y-yank-to-eol t)
  (evil-want-integration t)
  (evil-want-C-u-scroll t)
  (evil-want-C-i-jump t)
  (evil-undo-system 'undo-fu)
  (evil-echo-state nil)
  (evil-auto-indent t)
  :init
  (defun casmacs-elisp-lookup ()
    (interactive)
    (let ((sym (symbol-at-point)))
      (if sym
          (describe-symbol (symbol-at-point))
        (message "Invalid symbol"))))
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package evil-anzu
  :after evil
  :custom
  (anzu-cons-mode-line-p nil)
  :init
  (global-anzu-mode))

(use-package evil-goggles
  :after evil
  :hook (evil-mode . evil-goggles-mode)
  :custom
  (evil-goggles-duration 0.1)
  (evil-goggles-pulse nil)
  (evil-goggles-enable-delete nil)
  (evil-goggles-enable-change nil)
  :config
  (setq evil-goggles--commands
        `(,@evil-goggles--commands
          (lispyville-yank
            :face evil-goggles-yank-face
            :switch evil-goggles-enable-yank
            :advice evil-goggles--generic-async-advice)
          (lispyville-yank-line
            :face evil-goggles-yank-face
            :switch evil-goggles-enable-yank
            :advice evil-goggles--generic-async-advice)
          (lispyville-indent
            :face evil-goggles-indent-face
            :switch evil-goggles-enable-indent
            :advice evil-goggles--generic-async-advice)
          (lispyville-join
            :face evil-goggles-join-face
            :switch evil-goggles-enable-join
            :advice evil-goggles--join-advice)))
  (evil-goggles-use-diff-faces))


(use-package evil-surround
  :after evil
  :hook prog-mode
  :config
  (setq evil-surround-pairs-alist
        `((?\( '("(" . ")"))
          (?\[ '("[" . "]"))
          (?\{ '("{" . "}"))
          (?\) '("( " . " ))"))
          (?\] '("[ " . " ])"))
          (?\} '("{ " . " })"))
          ,@evil-surround-pairs-alist)))

(use-package evil-lion
  :config
  (evil-lion-mode))

(use-package ace-window
  :init
  (global-set-key [remap other-window] #'ace-window)
  :config
  (setq aw-keys '(?r ?s ?t ?h ?n ?i ?a ?o))
  (setq aw-scope 'frame
        aw-background t))

(provide  'cas-emacs-evil)
