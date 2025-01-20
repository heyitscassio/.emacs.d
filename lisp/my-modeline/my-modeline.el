;;; my-modeline.el --- My modeline -*- lexical-binding: t -*-

;;; Code:

(defgroup my-modeline-faces nil
  "My modeline faces"
  :group 'my-modeline)

(defface my-modeline
  '((t ()))
  "Default face."
  :group 'my-modeline-faces)

(defface my-modeline-emphasis
  '((t (:inherit (my-modeline mode-line-emphasis))))
  "Emphasis color"
  :group 'my-modeline-faces)

(defface my-modeline-info
  '((t (:inherit (my-modeline success))))
  "Info color"
  :group 'my-modeline-faces)

(defface my-modeline-warning
  '((t (:inherit (my-modeline warning))))
  "Warning color"
  :group 'my-modeline-faces)

(defface my-modeline-urgent
  '((t (:inherit (my-modeline error))))
  "Urgent color"
  :group 'my-modeline-faces)

(defface my-modeline-persp-name
  '((t (:inherit (my-modeline font-lock-comment-face italic))))
  "Persp indicator color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-macro-indicator
  '((t (:inherit (my-modeline font-lock-builtin-face))))
  "Macro indicator color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-emacs-state
  '((t (:inherit (my-modeline font-lock-builtin-face))))
  "Emacs state color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-insert-state
  '((t (:inherit (my-modeline font-lock-keyword-face))))
  "Insert state color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-motion-state
  '((t (:inherit (my-modeline font-lock-doc-face) :slant normal)))
  "Motion state color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-normal-state
  '((t (:inherit (my-modeline my-modeline-info))))
  "Normal state color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-operator-state
  '((t (:inherit (my-modeline mode-line))))
  "Operator state color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-visual-state
  '((t (:inherit (my-modeline my-modeline-warning))))
  "Visual state color"
  :group 'my-modeline-faces)

(defface my-modeline-evil-replace-state
  '((t (:inherit (my-modeline my-modeline-urgent))))
  "Replace state color"
  :group 'my-modeline-faces)

(defface my-modeline-minibuffer-state
  '((t (:inherit (my-modeline my-modeline-urgent))))
  "Minibuffer state color"
  :group 'my-modeline-faces)

(defun my-modeline--window-selected-p ()
  (let ((window (selected-window)))
    (or (eq window (old-selected-window))
        (and (minibuffer-window-active-p (minibuffer-window))
             (with-selected-window (minibuffer-window)
               (eq window (minibuffer-selected-window)))))))

(defun my-modeline--escape (str)
  (replace-regexp-in-string "%" "%%" str))

(defun my-modeline--fill (reserve)
  "Return empty space using FACE and leaving RESERVE space on the right."
  (when (and window-system (eq 'right (get-scroll-bar-mode)))
    (setq reserve (- reserve 3)))
  (propertize " "
              'display
              `((space :align-to (- (+ right right-fringe right-margin) ,reserve)))))

(defun my-modeline--format (left right)
  (let* ((right-format (format-mode-line right))
        (left-format (format-mode-line left))
        (fill (my-modeline--fill (length right-format))))
    (list
     left-format
     fill
     right-format)))

(defun my-modeline--warning ()
  '(:propertize "%e" face warning))

(defun my-modeline--buffer-name ()
  "Return `buffer-name' with spaces around it."
  (propertize
   (format "%s" (buffer-name))
   'face
   (if (buffer-modified-p) 'my-modeline-warning nil)))

(defvar-local my-modeline-buffer-name
  '(:eval (my-modeline--buffer-name)))

(defconst my-modeline--evil-state-tags
  '((normal     :short "<N>"   :long "NORMAL" :dot "●")
    (insert     :short "<I>"   :long "INSERT" :dot "●")
    (visual     :short "<V>"   :long "VISUAL" :dot "●")
    (vblock     :short "<Vb>"  :long "VBLOCK" :dot "●")
    (vline      :short "<Vl>"  :long "VLINE" :dot "●")
    (vsline     :short "<Vsl>" :long "VSLINE" :dot "●")
    (motion     :short "<M>"   :long "MOTION" :dot "●")
    (emacs      :short "<E>"   :long "EMACS" :dot "●")
    (operator   :short "<O>"   :long "OPERATE" :dot "●")
    (replace    :short "<R>"   :long "REPLACE" :dot "●")
    (minibuf    :short "<Mb>"   :long "MINIBUF" :dot "●")))

(defun my-modeline--evil-get-tag (state variant)
  (let ((tags (alist-get state my-modeline--evil-state-tags)))
    (format " %s " (plist-get tags variant))))

(defun my-modeline--evil-propretize-tag (variant)
  (let ((state evil-state))
    (if (active-minibuffer-window)
        (propertize (my-modeline--evil-get-tag 'minibuf variant) 'face 'my-modeline-minibuffer-state)
      (pcase state
          ('normal (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-evil-normal-state))
          ('insert (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-evil-insert-state))
          ('visual (pcase evil-visual-selection
                     ('line (propertize (my-modeline--evil-get-tag 'vline variant) 'face 'my-modeline-evil-visual-state))
                     ('screen-line (propertize (my-modeline--evil-get-tag 'vsline variant) 'face 'my-modeline-evil-visual-state))
                     ('block (propertize (my-modeline--evil-get-tag 'vblock variant) 'face 'my-modeline-evil-visual-state))
                     (_ (propertize (my-modeline--evil-get-tag 'visual variant) 'face 'my-modeline-evil-visual-state))))
          ('motion (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-evil-motion-state))
          ('emacs (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-evil-emacs-state))
          ('operator (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-evil-operator-state))
          ('replace (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-evil-replace-state))
          (_ (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-info))))))

(defun my-modeline--evil-state-tag (variant)
  (my-modeline--evil-propretize-tag variant))

(defun my-modeline--evil-macro ()
  (when-let ((macro evil-this-macro))
    (propertize (format " @%c" macro)
                'face
                'my-modeline-evil-macro-indicator
                'mouse-face 'mode-line-highlight)))

(defun my-modeline--evil ()
  (let ((anzu-state (anzu--update-mode-line)))
    (if (my-modeline--window-selected-p)
        (if anzu-state
            (propertize anzu-state 'face 'my-modeline-info)
          (format "%s" (my-modeline--evil-state-tag :dot)))
      "")))

(defvar-local my-modeline-evil
    '(:eval (list (my-modeline--evil)
                  (my-modeline--evil-macro))))

(defun my-modeline--major-mode ()
  (format "%s" (string-replace
                  "-"
                  " "
                  (capitalize
                   (string-replace
                    "-mode"
                    ""
                    (symbol-name major-mode))))))

(defvar-local my-modeline-major-mode
  '(:eval (my-modeline--major-mode)))

(defun my-modeline--buffer-state ()
  (cond
   ((let ((file-name (buffer-file-name)))
      (and file-name (not (file-exists-p file-name))))
    (propertize  "- " 'face 'my-modeline-urgent))
   ((buffer-modified-p) (propertize "* " 'face 'my-modeline-warning))
   (t nil)))

(defvar-local my-modeline-buffer-state
  '(:eval (my-modeline--buffer-state)))

(defvar flymake-mode nil)

(defun my-modeline--flymake ()
  (when (and (bound-and-true-p flymake-mode)
           flymake-mode)
    '(:eval (list flymake-mode-line-exception flymake-mode-line-counters))))

(defvar-local my-modeline-flymake
  '(:eval (my-modeline--flymake)))

(defun my-modeline--vc-branch ()
  (when-let* ((file (buffer-file-name))
              (branch (vc-git--symbolic-ref file)))
    (propertize (format " %s" branch)
                'face
                'my-modeline-emphasis
                'mouse-face 'mode-line-highlight)))

(defvar-local my-modeline-vc-branch
  '(:eval (my-modeline--vc-branch)))

(defun my-modeline--persp ()
  (when (and persp-mode (my-modeline--window-selected-p))
    (let ((persp-name (safe-persp-name (get-current-persp))))
      (propertize (format " %s" persp-name)
                  'face (if (eq persp-name persp-nil-name)
                            'shadow
                          'my-modeline-persp-name)))))

(defvar-local my-modeline-persp
  '(:eval (my-modeline--persp)))

(defun my-modeline--project ()
  (when-let ((current (project-current)))
    (propertize (format " [%s]" (project-name current)) 'face 'my-modeline-info)))

(defvar-local my-modeline-project
  '(:eval (my-modeline--project)))

(defvar-local my-modeline-left
    (list my-modeline-evil
          my-modeline-buffer-state
          my-modeline-buffer-name
          my-modeline-project
          mode-line-position-column-line-format))

(defvar-local my-modeline-right
    (list my-modeline-flymake
          my-modeline-persp
          my-modeline-vc-branch
          " "
          my-modeline-major-mode
          " "))

(defvar my-modeline-format
  '(:eval (my-modeline--format my-modeline-left my-modeline-right)))

(provide 'my-modeline)

;;; my-modeline.el ends here
;; (setq mode-line-format my-modeline-format)
