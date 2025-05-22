;; -*- lexical-binding: t; -*-

(use-package general
  :config
  (general-create-definer general-leader
    :states 'normal
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")
  (general-create-definer general-local-leader
    :states 'normal
    :prefix "SPC m"
    :global-prefix "C-SPC m"))

(provide 'cas-emacs-general)
