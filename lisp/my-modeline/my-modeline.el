;;; my-modeline.el --- My modeline -*- lexical-binding: t -*-

;;; Code:

(defgroup my-modeline-faces nil
  "My modeline faces"
  :group 'my-modeline)

(modus-themes-with-colors
  (defface my-modeline-blue-fg
    `((t :foreground ,blue))
    "Blue foreground face"
    :group 'my-modeline-faces)
  (defface my-modeline-yellow-fg
    `((t :foreground ,yellow))
    "Blue foreground face"
    :group 'my-modeline-faces)
  (defface my-modeline-yellow-bg
    `((t :background ,yellow))
    "Blue foreground face"
    :group 'my-modeline-faces)
  (defface my-modeline-magenta-fg
    `((t :foreground ,magenta))
    "Blue foreground face"
    :group 'my-modeline-faces)
  (defface my-modeline-red-fg
    `((t :foreground ,red-faint))
    "Blue foreground face"
    :group 'my-modeline-faces)
  (defface my-modeline-green-fg
    `((t :foreground ,green))
    "Blue foreground face"
    :group 'my-modeline-faces)
  (defface my-modeline-blue-indicator
    `((t :foreground ,bg-main :background ,blue))
    "Blue indicator"
    :group 'my-modeline-faces)
  (defface my-modeline-yellow-indicator
    `((t :foreground ,bg-main :background ,yellow))
    "Yellow indicator"
    :group 'my-modeline-faces)
  (defface my-modeline-magenta-indicator
    `((t :foreground ,bg-main :background ,magenta))
    "Magenta indicator"
    :group 'my-modeline-faces)
  (defface my-modeline-red-indicator
    `((t :foreground ,bg-main :background ,red))
    "Red indicator"
    :group 'my-modeline-faces)
  (defface my-modeline-green-indicator
    `((t :foreground ,bg-main :background ,green))
    "Green indicator"
    :group 'my-modeline-faces))

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
   (if (buffer-modified-p) 'my-modeline-red-fg nil)))

(defvar-local my-modeline-buffer-name
  '(:eval (my-modeline--buffer-name)))

(defconst my-modeline--evil-state-tags
  '((normal     :short "<N>"   :long "NORMAL")
    (insert     :short "<I>"   :long "INSERT")
    (visual     :short "<V>"   :long "VISUAL")
    (vblock     :short "<Vb>"  :long "VBLOCK")
    (vline      :short "<Vl>"  :long "VLINE")
    (vsline     :short "<Vsl>" :long "VSLINE")
    (motion     :short "<M>"   :long "MOTION")
    (emacs      :short "<E>"   :long "EMACS")
    (operator   :short "<O>"   :long "OPERATE")
    (replace    :short "<R>"   :long "REPLACE")))

(defun my-modeline--evil-get-tag (state variant)
  (let ((tags (alist-get state my-modeline--evil-state-tags)))
    (format " %s " (plist-get tags variant))))

(defun my-modeline--evil-propretize-tag (variant)
  (let ((state evil-state))
    (if (active-minibuffer-window)
        (propertize " MINIBUF " 'face 'my-modeline-red-indicator)
      (pcase state
          ('normal (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-blue-indicator))
          ('insert (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-magenta-indicator))
          ('visual (pcase evil-visual-selection
                     ('line (propertize (my-modeline--evil-get-tag 'vline variant) 'face 'my-modeline-yellow-indicator))
                     ('screen-line (propertize (my-modeline--evil-get-tag 'vsline variant) 'face 'my-modeline-yellow-indicator))
                     ('block (propertize (my-modeline--evil-get-tag 'vblock variant) 'face 'my-modeline-yellow-indicator))
                     (_ (propertize (my-modeline--evil-get-tag 'visual variant) 'face 'my-modeline-yellow-indicator))))
          ('motion (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-yellow-indicator))
          ('emacs (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-magenta-indicator))
          ('operator (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-red-indicator))
          ('replace (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-red-indicator))
          (_ (propertize (my-modeline--evil-get-tag state variant) 'face 'my-modeline-blue-fg))))))

(defun my-modeline--evil-state-tag (variant)
  (my-modeline--evil-propretize-tag variant))

(defun my-modeline--evil-macro ()
  (when-let ((macro evil-this-macro))
    (propertize (format " @%c" macro)
                'face
                'my-modeline-magenta-fg
                'mouse-face 'mode-line-highlight)))

(defun my-modeline--evil ()
  (let ((anzu-state (anzu--update-mode-line)))
    (if (my-modeline--window-selected-p)
        (if anzu-state
            (propertize anzu-state 'face 'my-modeline-blue-indicator)
          (format "%s" (my-modeline--evil-state-tag :long)))
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
   ((not (file-exists-p (buffer-file-name))) " -")
   ((buffer-modified-p) " *")
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
                'my-modeline-magenta-fg
                'mouse-face 'mode-line-highlight)))

(defvar-local my-modeline-vc-branch
  '(:eval (my-modeline--vc-branch)))

(defun my-modeline--persp ()
  (when (and persp-mode (my-modeline--window-selected-p))
    (let ((persp-name (safe-persp-name (get-current-persp))))
      (propertize (format " %s" persp-name)
                  'face (if (eq persp-name persp-nil-name)
                            'shadow
                          'my-modeline-green-fg)))))

(defvar-local my-modeline-persp
  '(:eval (my-modeline--persp)))

(defun my-modeline--project ()
  (when-let ((current (project-current)))
    (format " [%s]" (project-name current))))

(defvar-local my-modeline-project
  '(:eval (my-modeline--project)))

(defvar-local my-modeline-left
    (list my-modeline-evil
          " "
          my-modeline-buffer-name
          my-modeline-buffer-state
          my-modeline-project
          mode-line-position-column-line-format))

(defvar-local my-modeline-right
    (list
     my-modeline-flymake
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
