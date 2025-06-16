;;; cas-modeline.el --- My modeline -*- lexical-binding: t -*-

;;; Code:

(defgroup cas-modeline nil
  "Custom modeline"
  :group 'mode-line)

(defgroup cas-modeline-faces nil
  "My modeline faces"
  :group 'cas-modeline)

(defface cas-modeline
  '((t ()))
  "Default face."
  :group 'cas-modeline-faces)

(defface cas-modeline-emphasis
  '((t (:inherit (cas-modeline mode-line-emphasis))))
  "Emphasis color"
  :group 'cas-modeline-faces)

(defface cas-modeline-info
  '((t (:inherit (cas-modeline success))))
  "Info color"
  :group 'cas-modeline-faces)

(defface cas-modeline-warning
  '((t (:inherit (cas-modeline warning))))
  "Warning color"
  :group 'cas-modeline-faces)

(defface cas-modeline-urgent
  '((t (:inherit (cas-modeline error))))
  "Urgent color"
  :group 'cas-modeline-faces)

(defface cas-modeline-persp-name
  '((t (:inherit (cas-modeline font-lock-function-name-face italic))))
  "Persp indicator color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-state
  '((t (:inverse-video t)))
  "Evil state indicator"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-macro-indicator
  '((t (:inherit (cas-modeline font-lock-builtin-face cas-modeline-evil-state))))
  "Macro indicator color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-emacs-state
  '((t (:inherit (cas-modeline font-lock-builtin-face cas-modeline-evil-state))))
  "Emacs state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-insert-state
  '((t (:inherit (cas-modeline font-lock-keyword-face cas-modeline-evil-state))))
  "Insert state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-motion-state
  '((t (:inherit (cas-modeline font-lock-doc-face cas-modeline-evil-state) :slant normal)))
  "Motion state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-normal-state
  '((t (:inherit (cas-modeline cas-modeline-info cas-modeline-evil-state))))
  "Normal state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-operator-state
  '((t (:inherit (cas-modeline mode-line cas-modeline-evil-state))))
  "Operator state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-visual-state
  '((t (:inherit (cas-modeline cas-modeline-warning cas-modeline-evil-state))))
  "Visual state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-evil-replace-state
  '((t (:inherit (cas-modeline cas-modeline-urgent cas-modeline-evil-state))))
  "Replace state color"
  :group 'cas-modeline-faces)

(defface cas-modeline-minibuffer-state
  '((t (:inherit (cas-modeline cas-modeline-urgent cas-modeline-evil-state))))
  "Minibuffer state color"
  :group 'cas-modeline-faces)

(defun cas-modeline--window-selected-p ()
  (let ((window (selected-window)))
    (or (eq window (old-selected-window))
        (and (minibuffer-window-active-p (minibuffer-window))
             (with-selected-window (minibuffer-window)
               (eq window (minibuffer-selected-window)))))))

(defun cas-modeline--escape (str)
  (replace-regexp-in-string "%" "%%" str))

(defun cas-modeline--fill (reserve)
  "Return empty space using FACE and leaving RESERVE space on the right."
  (when (and window-system (eq 'right (get-scroll-bar-mode)))
    (setq reserve (- reserve 3)))
  (propertize " "
              'display
              `((space :align-to (- (+ right right-fringe right-margin) ,reserve)))))

(defun cas-modeline--format (left right)
  (let* ((right-format (format-mode-line right))
        (left-format (format-mode-line left))
        (fill (cas-modeline--fill (length right-format))))
    (list
     left-format
     fill
     right-format)))

(defun cas-modeline--warning ()
  '(:propertize "%e" face warning))

(defun cas-modeline--buffer-name ()
  "Return `buffer-name' with spaces around it."
  (propertize
   (format "%s" (buffer-name))
   'face
   (if (buffer-modified-p) 'cas-modeline-warning nil)))

(defvar-local cas-modeline-buffer-name
  '(:eval (cas-modeline--buffer-name)))

(defconst cas-modeline--evil-state-tags
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

(defun cas-modeline--evil-get-tag (state variant)
  (let ((tags (alist-get state cas-modeline--evil-state-tags)))
    (format " %s " (plist-get tags variant))))

(defun cas-modeline--evil-propretize-tag (variant)
  (let ((state evil-state))
    (if (active-minibuffer-window)
        (propertize (cas-modeline--evil-get-tag 'minibuf variant) 'face 'cas-modeline-minibuffer-state)
      (pcase state
          ('normal (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-evil-normal-state))
          ('insert (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-evil-insert-state))
          ('visual (pcase evil-visual-selection
                     ('line (propertize (cas-modeline--evil-get-tag 'vline variant) 'face 'cas-modeline-evil-visual-state))
                     ('screen-line (propertize (cas-modeline--evil-get-tag 'vsline variant) 'face 'cas-modeline-evil-visual-state))
                     ('block (propertize (cas-modeline--evil-get-tag 'vblock variant) 'face 'cas-modeline-evil-visual-state))
                     (_ (propertize (cas-modeline--evil-get-tag 'visual variant) 'face 'cas-modeline-evil-visual-state))))
          ('motion (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-evil-motion-state))
          ('emacs (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-evil-emacs-state))
          ('operator (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-evil-operator-state))
          ('replace (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-evil-replace-state))
          (_ (propertize (cas-modeline--evil-get-tag state variant) 'face 'cas-modeline-info))))))

(defun cas-modeline--evil-state-tag (variant)
  (cas-modeline--evil-propretize-tag variant))

(defun cas-modeline--evil-macro ()
  (when-let ((macro evil-this-macro))
    (propertize (format " @%c" macro)
                'face
                'cas-modeline-evil-macro-indicator
                'mouse-face 'mode-line-highlight)))

(defun cas-modeline--evil ()
  (let ((anzu-state (anzu--update-mode-line)))
    (if (cas-modeline--window-selected-p)
        (if anzu-state
            (propertize anzu-state 'face 'cas-modeline-info)
          (format "%s " (cas-modeline--evil-state-tag :long)))
      "")))

(defvar-local cas-modeline-evil
    '(:eval (list (cas-modeline--evil)
                  (cas-modeline--evil-macro))))

(defun cas-modeline--major-mode ()
  (format "%s" (string-replace
                  "-"
                  " "
                  (capitalize
                   (string-replace
                    "-mode"
                    ""
                    (symbol-name major-mode))))))

(defvar-local cas-modeline-major-mode
  '(:eval (cas-modeline--major-mode)))

(defun cas-modeline--buffer-state ()
  (cond
   ((let ((file-name (buffer-file-name)))
      (and file-name (not (file-exists-p file-name))))
    (propertize  "- " 'face 'cas-modeline-urgent))
   ((buffer-modified-p) (propertize "* " 'face 'cas-modeline-warning))
   (t nil)))

(defvar-local cas-modeline-buffer-state
  '(:eval (cas-modeline--buffer-state)))

(defvar flymake-mode nil)

(defun cas-modeline--flymake ()
  (when (and (bound-and-true-p flymake-mode)
           flymake-mode)
    '(:eval (list flymake-mode-line-exception flymake-mode-line-counters))))

(defvar-local cas-modeline-flymake
  '(:eval (cas-modeline--flymake)))

(defun cas-modeline--vc-branch ()
  (when-let* ((file (buffer-file-name))
              (branch (vc-git--symbolic-ref file)))
    (propertize (format " %s" branch)
                'face
                'cas-modeline-emphasis
                'mouse-face 'mode-line-highlight)))

(defvar-local cas-modeline-vc-branch
  '(:eval (cas-modeline--vc-branch)))

(defun cas-modeline--persp ()
  (when (and (featurep 'perspective) persp-mode (cas-modeline--window-selected-p))
    (let ((persp-name (persp-current-name)))
      (propertize (format " %s" persp-name)
                  'face 'cas-modeline-persp-name))))

(defvar-local cas-modeline-persp
  '(:eval (cas-modeline--persp)))

(defun cas-modeline--project ()
  (when-let ((current (project-current)))
    (propertize (format " [%s]" (project-name current)) 'face 'cas-modeline-info)))

(defvar-local cas-modeline-project
  '(:eval (cas-modeline--project)))

(defvar-local cas-modeline-left
    (list cas-modeline-evil
          cas-modeline-buffer-state
          cas-modeline-buffer-name
          cas-modeline-project
          mode-line-position-column-line-format))

(defvar-local cas-modeline-right
    (list cas-modeline-flymake
          cas-modeline-persp
          cas-modeline-vc-branch
          " "
          cas-modeline-major-mode
          " "))

(defvar cas-modeline-format
  '(:eval (cas-modeline--format cas-modeline-left cas-modeline-right)))

(defvar cas-modeline--old-mode-line-format nil)

;;;###autoload
(define-minor-mode cas-modeline-mode
  "Toggle cas- modeline"
  :group 'cas-modeline
  :global t
  :lighter nil
  (if cas-modeline-mode
      (progn
        (setq cas-modeline--old-mode-line-format mode-line-format)
        (setq-default mode-line-format (list "%e" cas-modeline-format))
        (dolist (buf (buffer-list))
          (with-current-buffer buf
            (setq mode-line-format (list "%e" cas-modeline-format)))))
    (progn
      (setq-default mode-line-format cas-modeline--old-mode-line-format)
      (dolist (buf (buffer-list))
        (with-current-buffer buf
          (setq mode-line-format cas-modeline--old-mode-line-format))))))

(provide 'cas-modeline)

;;; cas-modeline.el ends here
