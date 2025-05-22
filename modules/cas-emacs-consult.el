;; -*- lexical-binding: t; -*-

(use-package consult
  :after perspective
  :config
  (consult-customize consult--source-buffer :hidden t :default nil)
  (add-to-list 'consult-buffer-sources persp-consult-source)

  :general
  (:keymaps 'minibuffer-local-map
   "C-r" 'consult-history)
  (general-leader
    "/" '(consult-ripgrep :which-key "Ripgrep")
    "SPC" '(consult-buffer :which-key "All Buffers")
    "si" '(consult-imenu :which-key "Imenu")
    "fF" '(consult-find :which-key "Find files")))

(use-package consult-project-extra
  :after consult
  :demand t
  :config
  (consult-customize
   consult-project-extra--source-file
   :hidden t
   :default nil
   :narrow ?f)
  (push consult-project-extra--source-file consult-buffer-sources))

(provide 'cas-emacs-consult)
