;; -*- lexical-binding: t; -*-

;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))

;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s seconds with %d garbage collections."
                     (emacs-init-time "%.2f")
                     gcs-done)))

;; Silence compiler warnings as they can be pretty disruptive
(setq native-comp-async-report-warnings-errors nil)

;; Set the right directory to store the native comp cache
(add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" user-emacs-directory))

(defvar ignored-buffers '("\\*Messages\\*"
                          "\\*straight-process\\*"
                          "\\*Help\\*"
                          "\\*Backtrace\\*"))

(defmacro remove-from-list (list value)
  `(setq ,list (remove ,value ,list)))

(unless (featurep 'straight)
  ;; Bootstrap straight.el
  (defvar bootstrap-version)
  (let ((bootstrap-file
         (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
        (bootstrap-version 5))
    (unless (file-exists-p bootstrap-file)
      (with-current-buffer
          (url-retrieve-synchronously
           "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
           'silent 'inhibit-cookies)
        (goto-char (point-max))
        (eval-print-last-sexp)))
    (load bootstrap-file nil 'nomessage)))

;; Use straight.el for use-package expressions
(straight-use-package 'use-package)

(straight-use-package '(setup :type git :host nil :repo "https://git.sr.ht/~pkal/setup"))
(require 'setup)

(setup-define :disabled
  (lambda ()
    `,(setup-quit))
  :documentation "Always stop evaluating the body.")

(setup-define :load-after
    (lambda (features &rest body)
      (let ((body `(progn
                     (require ',(setup-get 'feature))
                     ,@body)))
        (dolist (feature (if (listp features)
                             (nreverse features)
                           (list features)))
          (setq body `(with-eval-after-load ',feature ,body)))
        body))
  :documentation "Load the current feature after FEATURES."
  :indent 1)

(setup-define :file-match
  (lambda (regexp)
    `(add-to-list 'auto-mode-alist (cons ,regexp ',(setup-get 'mode))))
  :documentation "Associate the current mode with files that match REGEXP."
  :debug '(form)
  :repeatable t)

(setup-define :load-from
    (lambda (path)
      `(let ((path* (expand-file-name ,path)))
         (if (file-exists-p path*)
             (add-to-list 'load-path path*)
           ,(setup-quit))))
  :documentation "Add PATH to load path.
This macro can be used as NAME, and it will replace itself with
the nondirectory part of PATH.
If PATH does not exist, abort the evaluation."
  :shorthand (lambda (args)
               (intern
                (file-name-nondirectory
                 (directory-file-name (cadr args))))))

(setup-define :leader
  (lambda (&rest args)
    `(with-eval-after-load 'general
       (general-define-key ,@args
                           :states 'normal
                           :keymaps 'override
                           :prefix "SPC"
                           :global-prefix "C-SPC")))
  :documentation "Define a leader keybind"
  :debug '(form)
  :indent 0)

(setup-define :local-leader
  (lambda (&rest args)
    `(with-eval-after-load 'general
       (let ((map ',(setup-get 'map)))
         (general-define-key ,@args
                             :states 'normal
                             :keymaps map
                             :prefix "SPC m"
                             :global-prefix "C-SPC m"))))
  :documentation "Define a local leader keybind"
  :debug '(form)
  :indent 0)

(defun my/filter-straight-recipe (recipe)
    (let* ((plist (cdr recipe))
        (name (plist-get plist :straight)))
    (cons (if (and name (not (equal name t)))
      	  name
            (car recipe))
            (plist-put plist :straight nil))))

(setup-define :pkg
    (lambda (&rest recipe)
    `(straight-use-package ',(my/filter-straight-recipe recipe)))
    :documentation "Install RECIPE via straight.el"
    :shorthand #'cadr)

(setup-define :ignore-buffers
  (lambda (&rest buffers)
    `(setq ignored-buffers (append ignored-buffers ',buffers)))
  :documentation "Ignore buffers")

(setup-define :display-rule
  (lambda (condition &rest actions)
    `(add-to-list 'display-buffer-alist '(,condition . ,actions)))
  :documentation "Add to display buffer alist")

(defun open-emms-window ()
  (persp-switch "music")
  (emms-smart-browse))

(defun print-colors ()
  (let ((colors '(black red green yellow blue magenta cyan white)))
    (mapcar #'message
            (mapcar (lambda (color)
                      (format "%s = \"%s\" | \"%s\""
                              color
                              (face-foreground (intern (format "ansi-color-%s" color)))
                              (face-foreground (intern (format "ansi-color-bright-%s" color)))))
                    colors))))

(let ((default-directory (concat (file-name-directory user-init-file) "lisp")))
  (normal-top-level-add-subdirs-to-load-path))

(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 10)
(menu-bar-mode -1)
(blink-cursor-mode 0)
(set-default 'truncate-lines t)

(setq help-window-select t)

(setq display-buffer-alist
      '(("\\*[Hh]elp\\*"
         (display-buffer-in-side-window)
         (window-height . 0.25)
         (side . bottom)
         (slot . 0)
         (window-parameters . ((mode-line-format . none))))))

;; (setup (:pkg all-the-icons)
;;   ;; (:option all-the-icons-scale-factor 2
;;   ;;          all-the-icons-wicon-scale-factor 2)
;;   )

(setup (:pkg diff-hl)
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (global-diff-hl-mode))
;; (use-package git-gutter)

;; (setup (:pkg git-gutter)
;;   (global-git-gutter-mode))

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-follow-mouse 't)
(setq scroll-step 1) 
(setq use-dialog-box nil)

(setup (:pkg diminish))

(column-number-mode)

(setq display-line-numbers-type 'relative)

;; Enable line numbers for some modes
(dolist (mode '(text-mode-hook
                prog-mode-hook
                conf-mode-hook))
  (add-hook mode (lambda ()
                   ;; (setq display-line-numbers-width-start t)
                   ;; (setq display-line-numbers-width 1)
                   (display-line-numbers-mode 1))))

;; Override some modes which derive from the above
(dolist (mode '(org-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq large-file-warning-threshold nil)
(setq vc-follow-symlinks t)
(setq ad-redefinition-action 'accept)
;; annoying ass sound
(setq ring-bell-function 'ignore)
(defalias 'yes-or-no-p 'y-or-n-p)
(save-place-mode)

(setup (:pkg pulsar)
  (:when-loaded
    (:option pulsar-pulse-functions (append pulsar-pulse-functions
                                            '(evil-goto-line
                                              evil-goto-first-line
                                              evil-scroll-down
                                              evil-scroll-up
                                              evil-window-down
                                              evil-window-up
                                              evil-window-left
                                              evil-window-right
                                              evil-window-next
                                              evil-jump-backward
                                              evil-jump-forward))))
  (add-hook 'minibuffer-setup-hook #'pulsar-pulse-line)
  (advice-add 'my/switch-buffer :after (lambda (&rest _) (pulsar-pulse-line)))
  (:load-after consult
    (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
    (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry))
  (pulsar-global-mode))

(setup (:pkg rainbow-mode)
  (:leader
    "o r" '(rainbow-mode :which-key "Toggle rainbow mode")))

(defvar nextcloud-password)
(defvar nextcloud-user)
(defvar nextcloud-remote-path)
(defvar nextcloud-local-path)
(defvar nextcloud-url)

(defun sync-nextcloud ()
  (interactive)
  (let ((command (format "nextcloudcmd --password \"%s\" --user \"%s\" --path \"%s\" \"%s\" \"%s\""
                         nextcloud-password
                         nextcloud-user
                         nextcloud-remote-path
                         nextcloud-local-path
                         nextcloud-url)))
    (save-window-excursion
      (shell-command command))
    (message "sync done")
    (revert-buffer :ignore-auto :noconfirm)))

(setq org-agenda-files '("~/doc/agendas/agenda.org"))

(defvar my-font)
(defvar big-font-size)
(defvar big-font--last-size)

(setq my-font (font-spec :family "GoMono Nerd Font"))

(if (string= (system-name) "intus")
    (progn
      (font-put my-font :size 14)
      (setq big-font-size 18))
  (progn
    (font-put my-font :size 20)
    (setq big-font-size 25)))

(defun my/set-font-faces (font)
  (if window-system
      (let* ((main-font font)
             (fallback "monospace")
             (font (if (list-fonts main-font) main-font fallback)))
        (set-frame-font font nil t))))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame (my/set-font-faces my-font))))
  (my/set-font-faces my-font))

(define-minor-mode big-font-mode
  nil
  :global t
  (if big-font-mode
      (progn
        (setq big-font--last-size (font-get my-font :size))
        (font-put my-font :size big-font-size)
        (my/set-font-faces my-font))
    (progn
      (font-put my-font :size big-font--last-size)
      (setq big-font--last-size nil)
      (my/set-font-faces my-font))))

;; (setup (:pkg modus-themes :type git :host github :repo "protesilaos/modus-themes")
;;   (:require modus-themes)
;;   (:option
;;    modus-themes-common-palette-overrides `((cursor fg-main)
;;                                            (bg-hover-secondary unspecified)
;;                                            ,@modus-themes-preset-overrides-intense)
;;    modus-themes-italic-constructs t
;;    modus-themes-org-blocks 'gray-background)
;;   (modus-themes-select 'modus-vivendi-tinted))

(setup (:pkg ef-themes)
  (:require ef-themes)
  (ef-themes-select 'ef-winter))

(global-prettify-symbols-mode)

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(setup (:pkg no-littering)
 (require 'no-littering))

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

; Backup directory
(setq backup-directory-alist `((".*" . ,(expand-file-name "backups" user-emacs-directory)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "backups" user-emacs-directory) t))
      create-lockfiles nil
      backup-by-copying t
      version-control t
      delete-old-versions t
      vc-make-backup-files t
      kept-old-versions 10
      kept-new-versions 10)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(setup (:pkg undo-tree)
  (setq undo-tree-auto-save-history nil)
  (global-undo-tree-mode 1))

(setup (:pkg evil)
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump t)
  (setq evil-want-Y-yank-to-eol t)
  (setq evil-undo-system 'undo-tree)
  (setq evil-echo-state nil)
  (setq evil-auto-indent t)

  (setq evil-normal-state-tag (propertize " " 'face 'font-lock-number-face)
        evil-emacs-state-tag (propertize " " 'face 'font-lock-warning-face)
        evil-insert-state-tag (propertize " " 'face 'font-lock-string-face)
        evil-motion-state-tag (propertize " " 'face 'font-lock-constant-face)
        evil-visual-state-tag (propertize " " 'face 'font-lock-escape-face)
        evil-operator-state-tag (propertize " " 'face 'font-lock-function-name-face))

  (defun my/elisp-lookup ()
    (interactive)
    (let ((sym (symbol-at-point)))
      (if sym
          (describe-symbol (symbol-at-point))
        (message "Invalid symbol"))))

  (evil-mode 1)

  (dolist (mode '(custom-mode
                  eshell-mode
                  git-rebase-mode
                  erc-mode
                  circe-server-mode
                  circe-chat-mode
                  circe-query-mode
                  sauron-mode
                  term-mode))
    (add-to-list 'evil-emacs-state-modes mode))

  (:with-hook emacs-lisp-mode
    (:hook (setq evil-lookup-func #'my/elisp-lookup)))

  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(setup (:pkg evil-collection)
  (:load-after evil
    (evil-collection-init)))

(setup (:pkg evil-goggles)
  (:when-loaded
    (:option evil-goggles-enable-delete t
             evil-goggles-enable-change t
             evil-goggles--commands
             (append evil-goggles--commands
                     '((evil-magit-yank-whole-line
                        :face evil-goggles-yank-face
                        :switch evil-goggles-enable-yank
                        :advice evil-goggles--generic-async-advice)
                       (+evil:yank-unindented
                        :face evil-goggles-yank-face
                        :switch evil-goggles-enable-yank
                        :advice evil-goggles--generic-async-advice)
                       (+eval:region
                        :face evil-goggles-yank-face
                        :switch evil-goggles-enable-yank
                        :advice evil-goggles--generic-async-advice)
                       (lispyville-delete
                        :face evil-goggles-delete-face
                        :switch evil-goggles-enable-delete
                        :advice evil-goggles--generic-blocking-advice)
                       (lispyville-delete-line
                        :face evil-goggles-delete-face
                        :switch evil-goggles-enable-delete
                        :advice evil-goggles--delete-line-advice)
                       (lispyville-yank
                        :face evil-goggles-yank-face
                        :switch evil-goggles-enable-yank
                        :advice evil-goggles--generic-async-advice)
                       (lispyville-yank-line
                        :face evil-goggles-yank-face
                        :switch evil-goggles-enable-yank
                        :advice evil-goggles--generic-async-advice)
                       (lispyville-change
                        :face evil-goggles-change-face
                        :switch evil-goggles-enable-change
                        :advice evil-goggles--generic-blocking-advice)
                       (lispyville-change-line
                        :face evil-goggles-change-face
                        :switch evil-goggles-enable-change
                        :advice evil-goggles--generic-blocking-advice)
                       (lispyville-change-whole-line
                        :face evil-goggles-change-face
                        :switch evil-goggles-enable-change
                        :advice evil-goggles--generic-blocking-advice)
                       (lispyville-indent
                        :face evil-goggles-indent-face
                        :switch evil-goggles-enable-indent
                        :advice evil-goggles--generic-async-advice)
                       (lispyville-join
                        :face evil-goggles-join-face
                        :switch evil-goggles-enable-join
                        :advice evil-goggles--join-advice)))))
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))

(setup (:pkg evil-anzu)
  (:load-after evil
    (global-anzu-mode 1)
    (require 'evil-anzu)))

(setup (:pkg which-key)
  (diminish 'which-key-mode)
  (which-key-mode)
  (setq which-key-idle-delay 0.3))

(setup (:pkg general)
  (:require general)
  (:leader
    "b" '(nil :which-key "Buffers")
    "br" '(revert-buffer :which-key "revert buffer")
    "bd" '(kill-current-buffer :which-key "kill current buffer")

    "f" '(nil :which-key "Files")
    "ff" '(find-file :which-key "Ripgrep")

    "h" '(nil :which-key "Help")
    "hc" '(describe-char :which-key "Describe Char")
    "hC" '(describe-command :which-key "Describe Command")
    "he" '(view-echo-area-messages :which-key "Show Echo Area Messages")
    "hf" '(describe-function :which-key "Describe Function")
    "hF" '(describe-face :which-key "Describe Face")
    "hv" '(describe-variable :which-key "Describe Variable")
    "hk" '(describe-key :which-key "Describe Key")

    "o" '(nil :which-key "Apps")
    "p" '(nil :which-key "Project")
    "pf" '(project-find-file :which-key "Project find file")
    "qK" '(save-buffers-kill-emacs :which-key "Apps")))

(setup (:pkg evil-surround)
  (global-evil-surround-mode))

;; TODO: Mode this to another section
;; (setq-default fill-column 80)

;; Turn on indentation and auto-fill mode for Org files
(defun my/org-mode-setup ()
  (org-indent-mode)
  (auto-fill-mode 0)
  (visual-line-mode 1)
  ;; (setq evil-auto-indent nil)
  (diminish org-indent-mode))

(setup (:pkg org)
  (:also-load org-tempo)
  (:hook my/org-mode-setup)
  (:local-leader
    "t" '(org-todo  :which-key "Mark todo")
    "T" '(org-todo-list  :which-key "Todo List")
    "x" '(org-toggle-checkbox :which-key "Toggle Checkbox")
    "d" '(nil :which-key "Dates")
    "dd" '(org-deadline :which-key "org-deadline")
    "ds" '(org-schedule :which-key "org-schedule")
    "dt" '(org-time-stamp :which-key "org-timestamp")
    "dT" '(org-time-stamp-inactive :which-key "org-timestamp"))
  (setq org-ellipsis " ▾"
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-hide-block-startup nil
        org-src-preserve-indentation nil
        org-startup-folded 'content
        org-cycle-separator-lines 2
        org-capture-bookmark nil)

  (require 'ox-latex)
  (add-to-list 'org-latex-packages-alist '("" "minted"))

  (setq org-latex-listings 'minted)

  (setq org-latex-pdf-process
        '("pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
          "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"
          "pdflatex -shell-escape -interaction nonstopmode -output-directory %o %f"))

  (setq org-refile-targets '((nil :maxlevel . 1)
                             (org-agenda-files :maxlevel . 1)))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)

  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
  (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup)

  (org-babel-do-load-languages
    'org-babel-load-languages
    '((emacs-lisp . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes))

;; This is needed as of Org 9.2
(setup org-tempo
  (:when-loaded
    (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
    (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
    (add-to-list 'org-structure-template-alist '("li" . "src lisp"))
    (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
    (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
    (add-to-list 'org-structure-template-alist '("py" . "src python"))
    (add-to-list 'org-structure-template-alist '("go" . "src go"))
    (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
    (add-to-list 'org-structure-template-alist '("json" . "src json"))))

(defun my/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name "~/.emacs.d/init.org"))
    (let ((org-config-babel-evaluate nil))
      (org-babel-tangle))))

  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook #'my/org-babel-tangle-config)))

(setup (:pkg minions)
  (:require minions))

(setup (:pkg nyan-mode)
  (nyan-mode))

(setq display-time-format "%l:%M %p %b %y"
      display-time-default-load-average nil)

(defun +my-mode-line/get-current-git-branch ()
  (when vc-mode
    (when-let* ((current-file (buffer-file-name)))
      (list
       " "
       (vc-git--symbolic-ref current-file)))))

(defun +my-mode-line/fill (reserve)
  "Return empty space using FACE and leaving RESERVE space on the right."
  (when
    (and window-system (eq 'right (get-scroll-bar-mode)))
    (setq reserve (- reserve 3)))
  (propertize " "
    'display
    `((space :align-to (- (+ right right-fringe right-margin) ,reserve)))))

(defun +my-mode-line/escape (str)
  (replace-regexp-in-string "%" "%%" str))

(defun +my-mode-line/format (left right)
  (let ((right-format (+my-mode-line/escape (format-mode-line right)))
        (left-format (+my-mode-line/escape (format-mode-line left))))
    (list
     left-format
     (+my-mode-line/fill (length right-format))
     right-format)))

(defun +my-modeline/show-persp ()
  (when (featurep 'persp-mode)
    (let* ((persp-names (remove "none" (mapcar #'safe-persp-name (persp-persps))))
           (format-name (lambda (name idx) (concat (int-to-string idx) " " name)))
           (current-persp (safe-persp-name (get-current-persp)))
           (idx (length persp-names))
           (formatted '()))
      (dolist (name persp-names)
        (setq formatted (append formatted
                                (list
                                 (when (not (string-equal name (car persp-names)))
                                   " ")
                                 (if (string-equal name current-persp)
                                     (propertize (funcall format-name name idx) 'face '(:inherit font-lock-keyword-face))
                                   (funcall format-name name idx))))
              idx (- idx 1)))
      (add-to-list 'formatted "[" t)
      (add-to-list 'formatted "]")
      (reverse formatted))))

;; (setq-default
;;  mode-line-format
;;  (list
;;   '(:eval
;;     (+my-mode-line/format
;;      (list
;;       evil-mode-line-tag
;;       '(:propertize "%e " face warning)
;;       `(:propertize "%b " face mode-line-emphasis help-echo ,(buffer-file-name))
;;       "[%+] "
;;       mode-line-position)
;;      (list
;;       '(:eval (+my-modeline/show-persp))
;;       " "
;;       `(:propertize
;;         "menu"
;;         mouse-face mode-line-highlight
;;         local-map ,(make-mode-line-mouse-map 'mouse-1 'minions-minor-modes-menu))
;;       '(:eval (when (and (featurep 'flymake) flymake-mode) flymake-mode-line-format))
;;       '(:eval (+my-mode-line/get-current-git-branch))
;;       " "
;;       mode-name
;;       " ")))))

(setup (:pkg nerd-icons))

(setup (:pkg minions)
  (:hook-into doom-modeline-mode))

(setup (:pkg doom-modeline)
  ;; (:hook-into after-init-hook)
  (:option doom-modeline-height 35
           doom-modeline-lsp t
           doom-modeline-github nil
           doom-modeline-mu4e nil
           ;; doom-modeline-irc t
           doom-modeline-minor-modes t
           doom-modeline-modal-icon nil
           doom-modeline-persp-name t
           doom-modeline-buffer-file-name-style 'truncate-except-project)

  (:load-after doom-modeline
    (doom-modeline-def-segment show-persp
      (when (featurep 'persp-mode)
        (let* ((persp-names (remove "none" (mapcar #'safe-persp-name (persp-persps))))
               (format-name (lambda (name idx) (concat (int-to-string idx) " " name)))
               (current-persp (safe-persp-name (get-current-persp)))
               (idx (length persp-names))
               (formatted '()))
          (dolist (name persp-names)
            (setq formatted (append formatted
                                    (list
                                     (when (not (string-equal name (car persp-names)))
                                       " ")
                                     (if (string-equal name current-persp)
                                         (propertize (funcall format-name name idx) 'face '(:inherit font-lock-keyword-face))
                                       (funcall format-name name idx))))
                  idx (- idx 1)))
          (add-to-list 'formatted " [" t)
          (add-to-list 'formatted "] ")
          (reverse formatted))))

    (doom-modeline-def-modeline 'my-simple-line
      '(bar modals matches buffer-info remote-host parrot selection-info)
      '(show-persp misc-info minor-modes input-method buffer-encoding major-mode process vcs checker)))

  (add-hook 'doom-modeline-mode-hook
            (lambda ()
              (doom-modeline-set-modeline 'my-simple-line 'default)))


  (doom-modeline-mode 1)

  (:load-after evil
    (setq evil-normal-state-tag ""
          evil-emacs-state-tag ""
          evil-insert-state-tag ""
          evil-motion-state-tag ""
          evil-visual-state-tag ""
          evil-operator-state-tag ""))
  (add-hook 'server-switch-hook #'force-mode-line-update))

(setup (:pkg workgroups))

(setup (:pkg persp-mode)
  (:leader
    "bD" '(persp-kill-buffer :which-key "Kill buffer")
    "TAB" '(:ignore t :which-key "Perspective")
    "TAB n" '(persp-switch :which-key "Switch perspective")
    "TAB k" '(persp-kill :which-key "Kill perspective")
    "TAB l" '(persp-next :which-key "Next perspective")
    "TAB h" '(persp-prev :which-key "Previous perspective"))
  (:leader
    "TAB 1" (lambda () (interactive) (persp-switch-by-index 0))
    "TAB 2" (lambda () (interactive) (persp-switch-by-index 1))
    "TAB 3" (lambda () (interactive) (persp-switch-by-index 2))
    "TAB 4" (lambda () (interactive) (persp-switch-by-index 3))
    "TAB 5" (lambda () (interactive) (persp-switch-by-index 4))
    "TAB 6" (lambda () (interactive) (persp-switch-by-index 5))
    "TAB 7" (lambda () (interactive) (persp-switch-by-index 6))
    "TAB 8" (lambda () (interactive) (persp-switch-by-index 7))
    "TAB 9" (lambda () (interactive) (persp-switch-by-index 8))
    "TAB 0" (lambda () (interactive) (persp-switch-by-index nil)))
  ;; (:hook-into emacs-startup-hook)
  (:load-after persp-mode-autoloads
    ;; (setq wg-morph-on nil) ;; switch off animation
    (setq persp-autokill-buffer-on-remove 'kill-weak)
    (add-hook 'window-setup-hook #'(lambda () (persp-mode 1))))

  (defun persp-switch-by-index (index)
    "Switch to perspective by index, if the index is larger than the last perspecive or nil, switch to last perspective"
    (let* ((persps (reverse (butlast (persp-persps))))
           (selected (if index
                         (nth index persps)
                       (car (last persps)))))
      (if selected
          (persp-switch (safe-persp-name selected))
        (persp-switch (safe-persp-name (car (last persps))))))))

(setq global-auto-revert-non-file-buffers t)

(setup (:require paren)
  (show-paren-mode 1))

(add-hook 'prog-mode-hook #'electric-indent-mode)

(setq tramp-default-method "ssh")

(setq-default indent-tabs-mode nil)

(setup (:pkg evil-commentary)
  (evil-commentary-mode))

(setq-default show-trailing-whitespace t)

(setup (:pkg lispyville)
  (:hook-into lispy-mode)
  (:when-loaded (lispyville-set-key-theme
                 '(slurp/barf-lispy operators c-w additional commentary))))

(setup (:pkg lispy)
  (:option lispy-close-quotes-at-end-p t)
  (:hook-into lisp-mode
              emacs-lisp-mode
              ielm-mode
              scheme-mode
              racket-mode
              hy-mode
              lfe-mode
              dune-mode
              clojure-mode
              fennel-mode)
  (:when-loaded
    (lispy-set-key-theme '(lispy c-digits))
  (define-minor-mode lispy-mode
    "Minor mode for navigating and editing LISP dialects.

When `lispy-mode' is on, most unprefixed keys,
i.e. [a-zA-Z+-./<>], conditionally call commands instead of
self-inserting. The condition (called special further on) is one
of:

- the point is before \"(\"
- the point is after \")\"
- the region is active

For instance, when special, \"j\" moves down one sexp, otherwise
it inserts itself.

When special, [0-9] call `digit-argument'.

When `lispy-mode' is on, \"[\" and \"]\" move forward and
backward through lists, which is useful to move into special.

\\{lispy-mode-map}"
    :keymap lispy-mode-map
    :group 'lispy
    :lighter " LY"
    (if lispy-mode
        (progn
          (require 'eldoc)
          (eldoc-remove-command 'special-lispy-eval)
          (eldoc-remove-command 'special-lispy-x)
          (eldoc-add-command 'lispy-space)
          (setq lispy-old-outline-settings
                (cons outline-regexp outline-level))
          (setq-local outline-level 'lispy-outline-level)
          (cond ((eq major-mode 'latex-mode)
                 (setq-local lispy-outline "^\\(?:%\\*+\\|\\\\\\(?:sub\\)?section{\\)")
                 (setq lispy-outline-header "%")
                 (setq-local outline-regexp "\\(?:%\\*+\\|\\\\\\(?:sub\\)?section{\\)"))
                ((eq major-mode 'clojure-mode)
                 (eval-after-load 'le-clojure
                   '(add-hook 'completion-at-point-functions #'lispy-clojure-complete-at-point nil t))
                 (setq-local outline-regexp (substring lispy-outline 1)))
                ((eq major-mode 'python-mode)
                 (setq-local lispy-outline "^#\\*+")
                 (setq lispy-outline-header "#")
                 (setq-local outline-regexp "#\\*+")
                 (setq-local outline-heading-end-regexp "\n"))
                (t
                 (setq-local outline-regexp (substring lispy-outline 1))))
          (when (called-interactively-p 'any)
            (mapc #'lispy-raise-minor-mode
                  (cons 'lispy-mode lispy-known-verbs)))
          (font-lock-add-keywords major-mode lispy-font-lock-keywords))
      (when lispy-old-outline-settings
        (setq outline-regexp (car lispy-old-outline-settings))
        (setq outline-level (cdr lispy-old-outline-settings))
        (setq lispy-old-outline-settings nil))
      (font-lock-remove-keywords major-mode lispy-font-lock-keywords)))))

(add-hook 'prog-mode-hook
          (lambda ()
            (electric-pair-local-mode t)))

(add-hook 'cider-repl-mode-hook
          (lambda ()
            (electric-pair-local-mode t)))

(setup (:pkg origami)
  (:hook-into yaml-mode))

(setup (:pkg envrc)
  (:ignore-buffers "\\*envrc\\*")
  (envrc-global-mode))

(setup (:pkg marginalia)
  (marginalia-mode))

(setup savehist
  (setq history-length 25)
  (savehist-mode 1))

(defun my/minibuffer-backward-kill (arg)
  "When minibuffer is completing a file name delete up to parent
folder, otherwise delete a word"
  (interactive "p")
  (if minibuffer-completing-file-name
      (if (string-match-p "/." (minibuffer-contents))
          (zap-up-to-char (- arg) ?/)
        (delete-minibuffer-contents))
      (kill-word (- arg))))

(setup (:pkg vertico)
  (vertico-mode)
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  (:with-map vertico-map
    (:bind "C-j" vertico-next
           "C-k" vertico-previous
           "C-f" vertico-exit))
  (:with-map minibuffer-local-map
    (:bind "C-<backspace>" my/minibuffer-backward-kill))
  (:option vertico-cycle t))

(setup (:pkg corfu)
  (:with-map corfu-map
    (:bind "C-s" corfu-quit
           [tab] corfu-next
           [backtab] corfu-previous))
  (:hook-into prog-mode-hook eshell-mode-hook)
  (:option corfu-cycle t
           corfu-auto t
           corfu-auto-delay 0.1
           corfu-auto-prefix 2
           corfu-quit-no-match nil
           corfu-preselect 'prompt)
  (:load-from "straight/build/corfu/extensions")
  (:require corfu-popupinfo)
  (:hook #'corfu-popupinfo-mode)
  (defun corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer if `completion-at-point' is bound."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-in-minibuffer))

(setup (:pkg cape)
  (:require cape)
  (add-to-list 'completion-at-point-functions #'cape-file))

(setup (:pkg orderless)
  (require 'orderless)
  (setq orderless-matching-styles '(orderless-flex orderless-literal orderless-regexp)
        completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles . (partial-completion))))))

(setup (:pkg consult)
  (:require consult)
  (:leader
    "SPC" '(my/switch-buffer :which-key "Buffers")
    "/" '(consult-ripgrep :which-key "Ripgrep")
    "bb" '(my/project-buffer :which-key "Project Buffers")
    "bB" '(consult-buffer :which-key "All Buffers"))

  (:with-map minibuffer-local-map
    (:bind "C-r" consult-history))

  (defun my/get-project-root ()
    (when (fboundp 'projectile-project-root)
      (projectile-project-root)))

  (:load-after persp-mode
    (defun my/switch-buffer ()
      (interactive)
      (with-persp-buffer-list
       nil
       (let ((consult-buffer-filter (append consult-buffer-filter ignored-buffers)))
         (consult-buffer))))

    (defun my/project-buffer ()
      (interactive)
      (let ((consult-buffer-filter (append consult-buffer-filter ignored-buffers)))
        (consult-project-buffer))))

  (:option consult-project-root-function #'my/get-project-root
           completion-in-region-function #'consult-completion-in-region))

(setup (:pkg cider)
  (:option cider-clojure-cli-global-options "-Adev"
           cider-repl-display-help-banner nil
           cider-eval-result-duration 'change
           cider-repl-pop-to-buffer-on-connect 'display-only)
  (:ignore-buffers "\\*cider-repl.*" "\\*nrepl-server .*")
  (:display-rule "\\*cider-repl.*"
                 (display-buffer-in-side-window)
                 ;; (dedicated . t)
                 (window-height  . 0.20)
                 ;; (window-parameters (no-other-window . t))
                 )
  (:with-map clojure-mode-map
    (:local-leader
      "e" '(nil :which-key "Eval")
      "eb" '(cider-eval-buffer :which-key "Eval buffer")
      "ed" '(cider-eval-defun-at-point :which-key "Eval debug")
      "'" '(cider-connect-clj :which-key "Connect clj")
      "\"" '(cider-connect-cljs :which-key "Connect cljs")
      "j" '(cider-jack-in-clj :which-key "Jack-in clj")
      "J" '(cider-jack-in-cljs :which-key "Jack-in cljs")))
  (add-to-list 'completion-category-defaults '(cider (styles basic)))
  (add-hook 'clojure-mode-hook #'cider-mode)
  (autoload 'cider--make-result-overlay "cider-overlays")

  ;; Cider eval overlays in elisp
  (defun my/eval-overlay (value point)
    (cider--make-result-overlay (format "%S" value)
      :where point)
    value)

  (advice-add 'eval-region :around
              (lambda (f beg end &rest r)
                (my/eval-overlay
                 (apply f beg end r)
                 end)))

  (advice-add 'eval-last-sexp :filter-return
              (lambda (r)
                (my/eval-overlay r (point))))

  (advice-add 'eval-defun :filter-return
              (lambda (r)
                (my/eval-overlay
                 r
                 (save-excursion
                   (end-of-defun)
                   (point))))))

;; (setup (:pkg nix-mode)
;;   (:file-match "*.nix"))


(setup (:pkg nix-mode))

(setup (:pkg lua-mode))

(setup (:pkg haskell-mode))

(setup (:pkg scala-mode))

(setup (:pkg go-mode))

(setup (:pkg moonscript))

(setup (:pkg typescript-mode)
  (:option typescript-indent-level 2))

(setup (:pkg emms)
  (:leader
    "o"  '(:ignore t :which-key "Open")
    "om" '(emms-smart-browse :which-key "EMMS"))
  (defun my-emms-browser-format-line (bdata &optional target)
    "Return a propertized string to be inserted in the buffer."
    (unless target
      (setq target 'browser))
    (let* ((name (or (emms-browser-bdata-name bdata) "misc"))
           (level (emms-browser-bdata-level bdata))
           (type (emms-browser-bdata-type bdata))
           (indent (emms-browser-make-indent level))
           (track (emms-browser-bdata-first-track bdata))
           (path (concat emms-source-file-default-directory "/"
                         (emms-track-get track 'name)))
           (face (emms-browser-get-face bdata))
           (format (emms-browser-get-format bdata target))
           (props (list 'emms-browser-bdata bdata))
           (format-choices
            `(("i" . ,indent)
              ("n" . ,name)
              ("y" . ,(emms-track-get-year track))
              ("A" . ,(emms-track-get track 'info-album))
              ("a" . ,(emms-track-get track 'info-artist))
              ("C" . ,(emms-track-get track 'info-composer))
              ("p" . ,(emms-track-get track 'info-performer))
              ("t" . ,(emms-track-get track 'info-title))
              ("D" . ,(emms-browser-disc-number track))
              ("T" . ,(emms-browser-track-number track))
              ("d" . ,(emms-browser-track-duration track))))
           str)
      (when (equal type 'info-album)
        (setq format-choices (append format-choices
                                     `(("cS" . ,(emms-browser-get-cover-str path 'small))
                                       ("cM" . ,(emms-browser-get-cover-str path 'medium))
                                       ("cL" . ,(emms-browser-get-cover-str path 'large))))))

      (when (functionp format)
        (setq format (funcall format bdata format-choices)))

      (setq str
            (with-temp-buffer
              (insert format)
              (goto-char (point-min))
              (let ((start (point-min)))
                ;; jump over any image
                (when (re-search-forward "%c[SML]" nil t)
                  (setq start (point)))
                ;; jump over the indent
                (when (re-search-forward "%i" nil t)
                  (setq start (point)))
                (add-text-properties start (point-max)
                                     (list 'face face)))
              (buffer-string)))

      (setq str (emms-browser-format-spec str format-choices))

      ;; give tracks a 'boost' if they're not top-level
      ;; (covers take up an extra space)
      (when (and (eq type 'info-title)
                 (not (string= indent "")))
        (setq str (concat " " str)))

      ;; if we're in playlist mode, add a track
      (when (and (eq target 'playlist)
                 (eq type 'info-title))
        (setq props
              (append props `(emms-track ,track))))

      ;; add properties to the whole string
      (add-text-properties 0 (length str) props str)
      str))
  (require 'emms-setup)
  (require 'emms-player-mpd)
  (emms-all)
  (setq emms-player-list '(emms-player-mpd))
  (setq emms-info-functions '(emms-info-mpd))
  (setq emms-browser-covers #'emms-browser-cache-thumbnail-async)
  (setq emms-browser-thumbnail-small-size 128)
  (setq emms-browser-thumbnail-medium-size 192)
  ;; (emms-mode-line-disable)
  (setq emms-source-file-default-directory "/mnt/extern/music/")
  (advice-add 'emms-browser-format-line :override #'my-emms-browser-format-line))

(setup (:pkg magit)
  (:option magit-display-buffer-function #'my/magit-buffer-function)
  (:option transient-display-buffer-action '(display-buffer-below-selected))
  (:ignore-buffers "^magit: .*")
  (:leader
    "g" '(:ignore t :which-key "Git")
    "gg" '(magit :which-key "Magit"))
    "gc" '(magit-smerge-keep-current :which-key "Keep current")
  (add-hook 'git-commit-mode-hook 'evil-insert-state)
  (defun my/magit-buffer-function (buffer)
    (let ((buffer-mode (buffer-local-value 'major-mode buffer)))
      (display-buffer
       buffer (cond
               ((and (eq buffer-mode 'magit-status-mode)
                     (get-buffer-window buffer))
                '(display-buffer-reuse-window))
               ;; Any magit buffers opened from a commit window should open below
               ;; it. Also open magit process windows below.
               ((or (bound-and-true-p git-commit-mode)
                    (eq buffer-mode 'magit-process-mode))
                (let ((size (if (eq buffer-mode 'magit-process-mode)
                                0.35
                              0.7)))
                  `(display-buffer-below-selected
                    . ((window-height . ,(truncate (* (window-height) size)))))))

               ;; Everything else should reuse the current window.
               ((or (not (derived-mode-p 'magit-mode))
                    (not (memq (with-current-buffer buffer major-mode)
                               '(magit-process-mode
                                 magit-revision-mode
                                 magit-diff-mode
                                 magit-stash-mode
                                 magit-status-mode))))
                '(display-buffer-same-window))
               nil)))))

(setup (:pkg restclient)
  (defun restclient-buffer ()
    (interactive)
    (switch-to-buffer "restclient.http")
    (restclient-mode))
  (:leader
    "o r" '(restclient-buffer :which-key "Open restclient buffer")))

(setup (:pkg gptel)
  (:option gptel-default-mode 'org-mode)
  (require 'my-secrets nil 't)
  (:load-after my-secrets
    (:option
     gptel-backend (gptel-make-gemini
                    "Gemini"
                    :key secrets-gemini-api-key
                    :stream t))))

(setup (:pkg eglot)
  (:ignore-buffers "^\\*EGLOT .*")
  (:local-leader
    "c" '(nil :which-key "Eglot")
    "cc" '(eglot-code-actions :which-key "Code Actions")
    "cr" '(eglot-rename :which-key "Rename"))
  (:option eglot-confirm-server-initiated-edits nil)
  (:with-mode (clojure-mode clojurescript-mode go-mode scala-mode c-mode)
    (:hook #'eglot-ensure))
  (:with-mode eglot-managed-mode
    (:hook (lambda ()
             "Make the eglot capf have less priority"
             (when (boundp 'cider-mode)
               (when cider-mode
                 (remove-from-list completion-at-point-functions t)
                 (remove-from-list completion-at-point-functions #'eglot-completion-at-point)
                 (add-to-list 'completion-at-point-functions #'eglot-completion-at-point t)
                 (add-to-list 'completion-at-point-functions t t)))))))

;; (setup (:pkg lsp-mode)
;;   (:option
;;    ;; lsp-disabled-clients '(semgrep-ls)
;;    ;; lsp-go-server-wrapper-function #'identity
;;    lsp-go-server-path "gopls")
;;   (:with-mode (go-mode)
;;     (:hook #'lsp-deferred)))

;; (lsp-go--server-command)

(setup (:pkg sideline)
  (:option sideline-backends-right '(sideline-flymake))
  (:hook-into flymake-mode))

(setup (:pkg sideline-flymake)
  (:option sideline-flymake-display-mode 'line))

(setup (:pkg yasnippet)
  (:with-mode (prog-mode)
    (:hook #'yas-minor-mode)))

(setup (:pkg eshell-toggle)
  (:leader
    "o o" '(eshell-toggle :which-key "Toggle Eshell"))
  (:option eshell-toggle-size-fraction 3
           eshell-toggle-run-command nil))
