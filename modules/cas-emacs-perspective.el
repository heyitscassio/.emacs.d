;; -*- lexical-binding: t; -*-

(use-package perspective
  ;; :hook ((kill-emacs . persp-state-save)
  ;;        (after-init . cas-emacs--load-persp))
  :custom
  (persp-state-default-file (expand-file-name "persp-state.eld" user-emacs-directory))
  (persp-suppress-no-prefix-key-warning t)
  :general
  (general-leader
    "bD" '(persp-kill-buffer* :which-key "Kill buffer")
    "bI" '(persp-ibuffer :which-key "Ibuffer")
    "TAB" '(:ignore t :which-key "Perspective")
    "TAB n" '(persp-switch :which-key "Switch perspective")
    "TAB k" '(persp-kill :which-key "Kill perspective")
    "TAB l" '(persp-next :which-key "Next perspective")
    "TAB h" '(persp-prev :which-key "Previous perspective")
    "TAB p" '(cas-emacs-switch-project-with-persp :which-key "Previous perspective"))
  :preface
  (defun cas-emacs--load-persp ()
    (when (file-exists-p persp-state-default-file)
      (persp-state-load persp-state-default-file)))
  (defun cas-emacs-switch-project-with-persp ()
    "Switch to a project and create a perspective named after it."
    (interactive)
    (let* ((project-dir (project-prompt-project-name))
           (project-name (file-name-nondirectory
                          (directory-file-name project-dir))))
      (persp-switch project-name)
      (condition-case nil
          (project-switch-project project-dir)
        (quit
         (persp-kill project-name)
         (signal 'quit nil)))))
  :init
  (persp-mode 1))

(provide 'cas-emacs-perspective)
