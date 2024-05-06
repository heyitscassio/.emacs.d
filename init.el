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
(setq straight-use-package-by-default t)

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
    (mapc #'message
            (mapcar (lambda (color)
                      (format "%s = %s | %s\n"
                              color
                              (face-foreground (intern (format "ansi-color-%s" color)))
                              (face-foreground (intern (format "ansi-color-bright-%s" color)))))
                    colors))))

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

(setup (:pkg evil-collection
             :host nil
             :type git
             :repo "git@github.com:toniz4/evil-collection.git")
  (:load-after evil
    (evil-collection-init)))

;; (setup (:pkg evil-goggles)
;;   (:when-loaded
;;     (:option evil-goggles-enable-delete t
;;              evil-goggles-enable-change t
;;              evil-goggles--commands
;;              (append evil-goggles--commands
;;                      '((evil-magit-yank-whole-line
;;                         :face evil-goggles-yank-face
;;                         :switch evil-goggles-enable-yank
;;                         :advice evil-goggles--generic-async-advice)
;;                        (+evil:yank-unindented
;;                         :face evil-goggles-yank-face
;;                         :switch evil-goggles-enable-yank
;;                         :advice evil-goggles--generic-async-advice)
;;                        (+eval:region
;;                         :face evil-goggles-yank-face
;;                         :switch evil-goggles-enable-yank
;;                         :advice evil-goggles--generic-async-advice)
;;                        (lispyville-delete
;;                         :face evil-goggles-delete-face
;;                         :switch evil-goggles-enable-delete
;;                         :advice evil-goggles--generic-blocking-advice)
;;                        (lispyville-delete-line
;;                         :face evil-goggles-delete-face
;;                         :switch evil-goggles-enable-delete
;;                         :advice evil-goggles--delete-line-advice)
;;                        (lispyville-yank
;;                         :face evil-goggles-yank-face
;;                         :switch evil-goggles-enable-yank
;;                         :advice evil-goggles--generic-async-advice)
;;                        (lispyville-yank-line
;;                         :face evil-goggles-yank-face
;;                         :switch evil-goggles-enable-yank
;;                         :advice evil-goggles--generic-async-advice)
;;                        (lispyville-change
;;                         :face evil-goggles-change-face
;;                         :switch evil-goggles-enable-change
;;                         :advice evil-goggles--generic-blocking-advice)
;;                        (lispyville-change-line
;;                         :face evil-goggles-change-face
;;                         :switch evil-goggles-enable-change
;;                         :advice evil-goggles--generic-blocking-advice)
;;                        (lispyville-change-whole-line
;;                         :face evil-goggles-change-face
;;                         :switch evil-goggles-enable-change
;;                         :advice evil-goggles--generic-blocking-advice)
;;                        (lispyville-indent
;;                         :face evil-goggles-indent-face
;;                         :switch evil-goggles-enable-indent
;;                         :advice evil-goggles--generic-async-advice)
;;                        (lispyville-join
;;                         :face evil-goggles-join-face
;;                         :switch evil-goggles-enable-join
;;                         :advice evil-goggles--join-advice)))))
;;   (evil-goggles-mode)
;;   (evil-goggles-use-diff-faces))

(setup (:pkg evil-anzu)
  (:load-after evil
    (:option anzu-cons-mode-line-p nil)
    (global-anzu-mode 1)
    (require 'evil-anzu)))

(setup (:pkg which-key)
  ;; (diminish 'which-key-mode)
  (which-key-mode)
  (setq which-key-idle-delay 0.3))

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

(use-package emacs
  :general
  (general-leader
    "b" '(nil :which-key "Buffers")
    "br" '(revert-buffer :which-key "revert buffer")
    "bd" '(kill-current-buffer :which-key "kill current buffer")

    "f" '(nil :which-key "Files")
    "ff" '(find-file :which-key "Find file")

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

(use-package evil-surround
  :init
  (global-evil-surround-mode))

(let ((default-directory (concat (file-name-directory user-init-file) "lisp")))
  (normal-top-level-add-subdirs-to-load-path))

(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode '(10 . nil))
(menu-bar-mode -1)
(blink-cursor-mode 0)
(set-default 'truncate-lines t)

(use-package diff-hl
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init
  (global-diff-hl-mode))

(setq help-window-select t)

(setq display-buffer-alist
      '(("\\*\\([Hh]elp\\|Messages\\)\\*"
         (display-buffer-in-side-window)
         (window-height . 0.25)
         (side . bottom)
         (slot . 0)
         (window-parameters . ((mode-line-format . none))))))

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-follow-mouse 't)
(setq scroll-conservatively 1000)
(setq scroll-margin 5)
(setq use-dialog-box nil)

(use-package diminish)

(column-number-mode)

(setq display-line-numbers-type 'relative)
(setq display-line-numbers-width-start t)
(setq display-line-numbers-grow-only t)

;; Enable line numbers for some modes
(dolist (mode '(text-mode-hook
                prog-mode-hook
                conf-mode-hook))
  (add-hook mode #'display-line-numbers-mode))

;; Override some modes which derive from the above
(dolist (mode '(org-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq large-file-warning-threshold nil)
(setq vc-follow-symlinks t)
(setq ad-redefinition-action 'accept)
;; annoying ass sound
(setq ring-bell-function 'ignore)
(defalias 'yes-or-no-p 'y-or-n-p)
(setq frame-resize-pixelwise 't)
(save-place-mode)

(use-package pulsar
  :hook ((minibuffer-setup . pulsar-pulse-line)
         (consult-after-jump . pulsar-recenter-top)
         (consult-after-jump . pulsar-reveal-entry))
  :config
  (setq pulsar-pulse-functions (append pulsar-pulse-functions
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
                                            evil-jump-forward)))
  :init
  (pulsar-global-mode))

(use-package rainbow-mode
  :hook (css-mode . rainbow-mode)
  :general
  (general-leader
   "o R" 'rainbow-mode))

(defvar nextcloud-password)
(defvar nextcloud-user)
(defvar nextcloud-remote-path)
(defvar nextcloud-local-path)
(defvar nextcloud-url)

(defun sync-nextcloud ()
  (interactive)
  (let ((command (format "nextcloudcmd --password '%s' --user '%s' --path '%s' '%s' '%s'"
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

(defvar after-enable-theme-hook nil
  "Normal hook run after enabling a theme.")

(defun run-after-enable-theme-hook (&rest _args)
  "Run `after-enable-theme-hook'."
  (run-hooks 'after-enable-theme-hook))

(advice-add 'enable-theme :after #'run-after-enable-theme-hook)

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering
  :init
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

(use-package fontaine
  :custom
  (fontaine-latest-state-file (locate-user-emacs-file "fontaine-latest-state.eld"))
  (fontaine-presets '((regular :default-height 170)
                      (big :default-height 200)
                      (t :default-family "Go Mono Nerd Font")))
  :config
  (fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))
  :init
  (fontaine-mode))

(use-package modus-themes
  :custom
  (modus-themes-italic-constructs t)
  (modus-themes-org-blocks 'gray-background)
  :config
  (setq modus-themes-common-palette-overrides modus-themes-preset-overrides-intense)
  (modus-themes-select 'modus-vivendi))

(global-prettify-symbols-mode)

(use-package org
  :general
  (general-local-leader
   :keymaps 'org-mode-map
   "t" '(org-todo  :which-key "Mark todo")
   "T" '(org-todo-list  :which-key "Todo List")
   "x" '(org-toggle-checkbox :which-key "Toggle Checkbox")
   "d" '(nil :which-key "Dates")
   "dd" '(org-deadline :which-key "org-deadline")
   "ds" '(org-schedule :which-key "org-schedule")
   "dt" '(org-time-stamp :which-key "org-timestamp")
   "dT" '(org-time-stamp-inactive :which-key "org-timestamp"))
  :custom
  (org-ellipsis " ▾")
  (org-hide-emphasis-markers t)
  (org-src-fontify-natively t)
  (org-fontify-quote-and-verse-blocks t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 2)
  (org-hide-block-startup nil)
  (org-src-preserve-indentation nil)
  (org-startup-folded 'content)
  (org-cycle-separator-lines 2)
  (org-capture-bookmark nil)
  :hook (org-mode . my-org-mode-setup)
  :init
  (defun my-org-mode-setup ()
    (org-indent-mode)
    (auto-fill-mode 0)
    (visual-line-mode 1))
  :config
  (require 'org-tempo)
  ;; (require 'ox-latex)

  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("li" . "src lisp"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("go" . "src go"))
  (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
  (add-to-list 'org-structure-template-alist '("json" . "src json")))

(defun my/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name "~/.emacs.d/init.org"))
    (let ((org-config-babel-evaluate nil))
      (org-babel-tangle))))

  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'after-save-hook #'my/org-babel-tangle-config)))

(use-package minions
  :init
  (minions-mode))

(use-package my-modeline
  :straight nil
  :config
  (setq-default mode-line-format my-modeline-format))

(use-package persp-mode
  :hook
  (window-setup . persp-mode)
  :general
  (general-leader
   "bD" '(persp-kill-buffer :which-key "Kill buffer")
   "TAB" '(:ignore t :which-key "Perspective")
   "TAB n" '(persp-switch :which-key "Switch perspective")
   "TAB k" '(persp-kill :which-key "Kill perspective")
   "TAB l" '(persp-next :which-key "Next perspective")
   "TAB h" '(persp-prev :which-key "Previous perspective")

   "TAB 1" (lambda () (interactive) (my-persp-switch-by-index 0))
   "TAB 2" (lambda () (interactive) (my-persp-switch-by-index 1))
   "TAB 3" (lambda () (interactive) (my-persp-switch-by-index 2))
   "TAB 4" (lambda () (interactive) (my-persp-switch-by-index 3))
   "TAB 5" (lambda () (interactive) (my-persp-switch-by-index 4))
   "TAB 6" (lambda () (interactive) (my-persp-switch-by-index 5))
   "TAB 7" (lambda () (interactive) (my-persp-switch-by-index 6))
   "TAB 8" (lambda () (interactive) (my-persp-switch-by-index 7))
   "TAB 9" (lambda () (interactive) (my-persp-switch-by-index 8))
   "TAB 0" (lambda () (interactive) (my-persp-switch-by-index nil)))
  :custom
  (persp-autokill-buffer-on-remove 'kill-weak)
  (persp-auto-resume-time 0.1)
  (add-to-list 'persp-save-buffer-functions #'my-persp-ignore-none-persp)
  :init
  (defun my-persp-switch-by-index (index)
    "Switch to perspective by index, if the index is larger than the last perspecive or nil, switch to last perspective"
    (let* ((persps (reverse (butlast (persp-persps))))
           (selected (if index
                         (nth index persps)
                       (car (last persps)))))
      (if selected
          (persp-switch (safe-persp-name selected))
        (persp-switch (safe-persp-name (car (last persps)))))))

  (defun my-persp-ignore-none-persp (buffer)
    (when (not (persp--buffer-in-persps buffer))
      'skip)))

(setq global-auto-revert-non-file-buffers t)

(use-package emacs
  :init
  (show-paren-mode))

(use-package aggressive-indent)

(add-hook 'prog-mode-hook #'electric-indent-mode)

(setq tramp-default-method "ssh")

(setq-default indent-tabs-mode nil)

(use-package evil-commentary
  :init
  (evil-commentary-mode))

(setq-default show-trailing-whitespace t)

(use-package smartparens
  :custom (sp-highlight-pair-overlay nil)
  :hook ((prog-mode text-mode) . smartparens-mode)
  :init
  (defun indent-between-pair (&rest _ignored)
    (newline)
    (indent-according-to-mode)
    (forward-line -1)
    (indent-according-to-mode))
  :config
  (require 'smartparens-config)
  (sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
  (sp-local-pair 'prog-mode "[" nil :post-handlers '((indent-between-pair "RET")))
  (sp-local-pair 'prog-mode "(" nil :post-handlers '((indent-between-pair "RET"))))

(use-package evil-cleverparens
  :hook ((lisp-mode
          emacs-lisp-mode
          ielm-mode
          scheme-mode
          racket-mode
          hy-mode
          lfe-mode
          dune-mode
          clojure-mode
          fennel-mode)
         . evil-cleverparens-mode))

(use-package origami
  :hook (yaml-mode . origami-mode))

(use-package envrc
  :init
  (envrc-global-mode))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package emacs
  :custom
  (history-length 25)
  :init
  (savehist-mode 1))

(use-package vertico
  :preface
  (defun my-minibuffer-backward-kill (arg)
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
            "C-<backspace>" 'my-minibuffer-backward-kill)
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
  :hook (((prog-mode eshell-mode) . corfu-mode)
         (corfu-mode . corfu-popupinfo-mode)
         (minibuffer-setup . corfu-enable-in-minibuffer))
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-popupinfo-delay '(1.0 . 0.5))
  (corfu-auto-delay 0)
  (corfu-auto-prefix 2)
  (corfu-quit-no-match nil)
  (corfu-preselect 'prompt)
  :general
  (:keymaps 'corfu-map
            "C-s" 'corfu-quit
            "<tab>" 'corfu-next
            "<backtab>" 'corfu-previous))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file))

(use-package orderless
  :custom
  (orderless-matching-styles '(orderless-literal orderless-flex orderless-regexp))
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles . (partial-completion))))))

(use-package consult
  :after persp-mode
  :init
  (with-eval-after-load 'consult
    (defun my/switch-buffer ()
      (interactive)
      (with-persp-buffer-list
       nil
       (let ((consult-buffer-filter (append consult-buffer-filter ignored-buffers)))
         (consult-buffer)))))
  :general
  (:keymaps 'minibuffer-local-map
            "C-r" 'consult-history)
  (general-leader
    "SPC" '(my/switch-buffer :which-key "Buffers")
    "/" '(consult-ripgrep :which-key "Ripgrep")
    "bB" '(consult-buffer :which-key "All Buffers")))

(use-package sly)

(use-package cider
  :hook (clojure-mode . cider-mode)
  :custom
  ;; (cider-clojure-cli-global-options "-Adev")
  (cider-repl-display-help-banner nil)
  (cider-eval-result-duration 'change)
  (cider-repl-pop-to-buffer-on-connect 'display-only)
  (cider-xref-fn-depth 90)
  (cider-offer-to-open-cljs-app-in-browser nil)
  :general
  (general-local-leader
    :keymaps 'clojure-mode-map
    "e" '(nil :which-key "Eval")
    "eb" '(cider-eval-buffer :which-key "Eval buffer")
    "ed" '(cider-debug-defun-at-point :which-key "Eval debug")
    "'" '(cider-connect-clj :which-key "Connect clj")
    "\"" '(cider-connect-cljs :which-key "Connect cljs")
    "j" '(cider-jack-in-clj :which-key "Jack-in clj")
    "J" '(cider-jack-in-cljs :which-key "Jack-in cljs")))

(use-package nix-mode)

(use-package lua-mode)

(use-package haskell-mode)

(use-package scala-mode)

(use-package go-mode)

(use-package typescript-mode
  :custom
  (typescript-indent-level 2))

(use-package yaml-mode)

(use-package emms
  :custom
  (emms-player-list '(emms-player-mpd))
  (emms-info-functions '(emms-info-mpd))
  (emms-source-file-default-directory "/mnt/extern/music")
  (emms-player-mpd-music-directory emms-source-file-default-directory)
  (emms-browser-covers #'emms-browser-cache-thumbnail-async)
  :config
  (require 'emms-setup)
  (require 'emms-player-mpd)
  (emms-all))

(use-package magit
  :hook (git-commit-mode . evil-insert-state)
  :custom
  (magit-display-buffer-function #'my-magit-buffer-function)
  (transient-display-buffer-action '(display-buffer-below-selected))
  :general
  (general-leader
    "g" '(:ignore t :which-key "Git")
    "gg" '(magit :which-key "Magit"))
  :config
  (defun my-magit-buffer-function (buffer)
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

(use-package restclient
  :general
  (general-leader
    "o r" '(restclient-buffer :which-key "Open restclient buffer"))
  :init
  (defun restclient-buffer ()
    (interactive)
    (switch-to-buffer "restclient.http")
    (restclient-mode)))

(use-package eglot
  :hook (((clojure-mode
           clojurescript-mode
           go-mode
           c-mode)
          .
          eglot-ensure)
         (eglot-managed-mode . my-eglot-lower-capf-prio))
  :custom
  (eglot-confirm-server-initiated-edits nil)
  (max-mini-window-height 2)
  :general
  (general-local-leader
    :keymaps 'eglot-mode-map
    "c" '(nil :which-key "Eglot")
    "cc" '(eglot-code-actions :which-key "Code Actions")
    "cr" '(eglot-rename :which-key "Rename"))
  :init
  (defun my-eglot-lower-capf-prio ()
    "Make the eglot capf have lower priority"
    (when (boundp 'cider-mode)
      (when cider-mode
        (remove-from-list completion-at-point-functions t)
        (remove-from-list completion-at-point-functions #'eglot-completion-at-point)
        (add-to-list 'completion-at-point-functions #'eglot-completion-at-point t)
        (add-to-list 'completion-at-point-functions t t)))))

(use-package sideline-flymake
  :custom
  (sideline-flymake-display-mode 'line))

(use-package sideline
  :hook (flymake-mode . sideline-mode)
  :custom
  (sideline-backends-right '(sideline-flymake)))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode))

(use-package my-eshell-toggle
  :straight nil
  :general
  (general-leader
    "o o" '(my-eshell-toggle :which-key "Toggle eshell")))

(use-package jarchive
  :init
  (jarchive-setup))
