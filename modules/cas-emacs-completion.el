;; -*- lexical-binding: t; -*-

(use-package marginalia
  :hook vertico-mode)

(use-package vertico
  :preface
  (defun casmacs-minibuffer-backward-kill (arg)
    "When minibuffer is completing a file name delete up to parent
folder, otherwise delete a word"
    (interactive "p")
    (if minibuffer-completing-file-name
        (if (string-match-p "/." (minibuffer-contents))
            (zap-up-to-char (- arg) ?/)
          (delete-minibuffer-contents))
      (kill-word (- arg))))
  :hook
  (minibuffer-setup . cursor-intangible-mode)
  :general
  (:keymaps 'vertico-map
            "C-j" 'vertico-next
            "C-k" 'vertico-previous
            "C-f" 'vertico-exit)
  (:keymaps 'minibuffer-local-map
            "C-<backspace>" 'casmacs-minibuffer-backward-kill)
  :custom
  (minibuffer-prompt-properties '(read-only t cursor-intangible t face minibuffer-prompt))
  (vertico-cycle t)
  :init
  (vertico-mode))

(use-package corfu
  :preface
  (defun corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer if `completion-at-point' is bound."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      (corfu-mode 1)))
  :hook (((prog-mode eshell-mode cider-repl-mode) . corfu-mode)
         (corfu-mode . corfu-popupinfo-mode)
         (corfu-mode . corfu-history-mode)
         (minibuffer-setup . corfu-enable-in-minibuffer))
  :custom
  (corfu-cycle t)
  (corfu-popupinfo-delay '(1.0 . 0.5))
  (corfu-auto-delay 0.3)
  (corfu-auto-prefix 0)
  (corfu-quit-no-match 'separator)
  (corfu-preselect 'prompt)
  (corfu-preview-current 'insert)
  (corfu-on-exact-match 'show)
  :general
  (:states 'insert "C-." 'completion-at-point)
  (:keymaps 'corfu-map
            "C-s" 'corfu-quit
            "<tab>" 'corfu-next
            "<backtab>" 'corfu-previous)
  (:keymaps 'corfu-popupinfo-map
            "C-M-k" 'corfu-popupinfo-scroll-up
            "C-M-j" 'corfu-popupinfo-scroll-down))

(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-use-icons nil)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package orderless
  :custom
  (completion-styles '(orderless-fast basic))
  (completion-category-overrides '((file (styles . (partial-completion)))))
  :config
  (defun orderless-fast-dispatch (word index total)
    (and (= index 0) (= total 1) (length< word 4)
         (cons 'orderless-literal-prefix word)))
  (orderless-define-completion-style orderless-fast
    (orderless-style-dispatchers '(orderless-fast-dispatch))
    (orderless-matching-styles '(orderless-literal orderless-regexp))))

(provide 'cas-emacs-completion)
