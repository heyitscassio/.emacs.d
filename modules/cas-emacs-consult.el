;; -*- lexical-binding: t; -*-

(use-package embark
  :after eldoc
  :hook (embark-collect-mode . (lambda () (setq-local show-trailing-whitespace nil)))
  :bind
  (("C-;" . embark-act)
   (:map minibuffer-local-map)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  (context-menu-mode 1)
  (add-hook 'context-menu-functions #'embark-context-menu 100)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))


(use-package consult
  :after perspective
  :custom
  (xref-show-xrefs-function #'consult-xref)
  :config
  (consult-customize consult-source-buffer :hidden t :default nil)
  (add-to-list 'consult-buffer-sources persp-consult-source)
  ;; (add-to-list 'consult-buffer-sources consult-project-buffer-sources)
  :general
  (:keymaps 'minibuffer-local-map
   "C-r" 'consult-history)
  (general-leader
    "/" '(consult-ripgrep :which-key "Ripgrep")
    "SPC" '(consult-buffer :which-key "All Buffers")
    "si" '(consult-imenu :which-key "Imenu")
    "fF" '(consult-find :which-key "Find files")))


;; (use-package consult-project-extra
;;   :after consult
;;   :custom (consult-project-function #'consult-project-extra-project-fn)
;;   :general
;;   (general-leader
;;     "pf" '(consult-project-extra-find :which-key "Project find file")))

(use-package embark-consult
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(provide 'cas-emacs-consult)
