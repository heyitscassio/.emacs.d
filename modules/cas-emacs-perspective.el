;; -*- lexical-binding: t; -*-

(use-package ibuffer)

(use-package perspective
  :hook (kill-emacs . persp-state-save)
  :custom
  (persp-state-default-file (expand-file-name "persp-state.eld" user-emacs-directory))
  :general
  (general-leader
    "bD" '(persp-kill-buffer* :which-key "Kill buffer")
    "bI" '(persp-ibuffer :which-key "Ibuffer")
    "TAB" '(:ignore t :which-key "Perspective")
    "TAB n" '(persp-switch :which-key "Switch perspective")
    "TAB k" '(persp-kill :which-key "Kill perspective")
    "TAB l" '(persp-next :which-key "Next perspective")
    "TAB h" '(persp-prev :which-key "Previous perspective"))
  :preface
  (defun cas-emacs--load-persp ()
    (when (file-exists-p persp-state-default-file)
      (persp-state-load persp-state-default-file)))
  :init
  (persp-mode 1)
  (cas-emacs--load-persp))

(provide 'cas-emacs-perspective)
