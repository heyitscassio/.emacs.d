;; -*- lexical-binding: t; -*-

;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s seconds with %d garbage collections."
                     (emacs-init-time "%.2f")
                     gcs-done)))

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

(straight-use-package 'use-package)
(setq straight-recipe-repositories '(melpa gnu-elpa-mirror nongnu-elpa el-get emacsmirror-mirror))

 (use-package straight
   :custom
   ;; add project and flymake to the pseudo-packages variable so straight.el doesn't download a separate version than what eglot downloads.
   (straight-built-in-pseudo-packages '(emacs nadvice python image-mode project flymake xref))
   (straight-use-package-by-default t))

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering
  :init
  (require 'no-littering))

;; Garbage collector
(use-package gcmh
  :init
  (gcmh-mode))

(use-package exec-path-from-shell
  :init
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(load custom-file t)

; Backup directory
(setq backup-directory-alist `((".*" . ,(expand-file-name "backups" user-emacs-directory)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "autosave/"  user-emacs-directory) t))
      create-lockfiles nil
      backup-by-copying t
      version-control t
      delete-old-versions t
      vc-make-backup-files t
      kept-old-versions 10
      kept-new-versions 10)

(use-package evil-goggles
  :hook (evil-mode . evil-goggles-mode)
  :custom
  (evil-goggles-duration 0.1)
  (evil-goggles-pulse nil)
  (evil-goggles-enable-delete nil)
  (evil-goggles-enable-change nil)
  :config
  (setq evil-goggles--commands
        `(,@evil-goggles--commands
          (lispyville-yank
            :face evil-goggles-yank-face
            :switch evil-goggles-enable-yank
            :advice evil-goggles--generic-async-advice)
          (lispyville-yank-line
            :face evil-goggles-yank-face
            :switch evil-goggles-enable-yank
            :advice evil-goggles--generic-async-advice)
          (lispyville-indent
            :face evil-goggles-indent-face
            :switch evil-goggles-enable-indent
            :advice evil-goggles--generic-async-advice)
          (lispyville-join
            :face evil-goggles-join-face
            :switch evil-goggles-enable-join
            :advice evil-goggles--join-advice)))
  (evil-goggles-use-diff-faces))

(use-package undo-fu)

(use-package undo-fu-session
  :init
  (undo-fu-session-mode))

(use-package vundo
  :custom
  (vundo-window-max-height nil)
  (vundo-roll-back-on-quit nil)
  :init
  (add-to-list 'display-buffer-alist
               '(" \\*vundo tree\\*"
                 (display-buffer-at-bottom)
                 (side . bottom)
                 (slot . 0)
                 (window-height . .33))))

(use-package evil
  :hook (emacs-lisp-mode . (lambda () (setq evil-lookup-func #'my-elisp-lookup)))
  :custom
  (evil-want-integration t)
  (evil-want-keybinding nil)
  (evil-want-C-u-scroll t)
  (evil-want-C-i-jump t)
  (evil-want-Y-yank-to-eol t)
  (evil-undo-system 'undo-fu)
  (evil-echo-state nil)
  (evil-auto-indent t)
  :init
  (defun my-elisp-lookup ()
    (interactive)
    (let ((sym (symbol-at-point)))
      (if sym
          (describe-symbol (symbol-at-point))
        (message "Invalid symbol"))))
  (evil-mode))

(use-package evil-collection
  :after evil
  :init
  (evil-collection-init))

(use-package evil-anzu
  :after evil
  :custom
  (anzu-cons-mode-line-p nil)
  :init
  (global-anzu-mode))

(use-package which-key
  :custom
  (which-key-idle-delay 1)
  :init
  (which-key-mode))

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
  :init
  (global-set-key (kbd "<escape>") 'keyboard-escape-quit)
  (setq frame-inhibit-implied-resize t)
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
    "qK" '(save-buffers-kill-emacs :which-key "Apps")
    "s" '(nil :which-key "Search")))

(use-package evil-surround
  :init
  (global-evil-surround-mode))

(let ((default-directory (concat (file-name-directory user-init-file) "lisp")))
  (normal-top-level-add-subdirs-to-load-path))

(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(fringe-mode '(5 . 5))

(if (not (eq system-type 'darwin))
    (menu-bar-mode -1))

(blink-cursor-mode 0)
(set-default 'truncate-lines t)

(use-package diff-hl
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init
  (define-fringe-bitmap 'my-diff-hl-bitmap [] 5 1 '(top t))
  (setq diff-hl-fringe-bmp-function (lambda (type pos) 'my-diff-hl-bitmap))
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
;; Hide useless commands in M-x
(setq read-extended-command-predicate #'command-completion-default-include-p)

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

(defvar after-enable-theme-hook nil
  "Normal hook run after enabling a theme.")

(defun run-after-enable-theme-hook (&rest _args)
  "Run `after-enable-theme-hook'."
  (run-hooks 'after-enable-theme-hook))

(advice-add 'enable-theme :after #'run-after-enable-theme-hook)

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'control
        mac-option-modifier 'meta
        mac-right-option-modifier 'none
        mac-control-modifier 'super
        mac-function-modifier 'hyper))

(use-package fontaine
  :custom
  (fontaine-latest-state-file (locate-user-emacs-file "fontaine-latest-state.eld"))
  (fontaine-presets '((regular :default-height 120)
                      (big :default-height 180)
                      (t :default-family "Menlo")))
  :config
  (fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))
  :init
  (fontaine-mode))

(defcustom my-dark-theme 'leuven-dark
  "My dark theme"
  :type 'symbol)

(defcustom my-light-theme 'leuven-light
  "My light theme"
  :type 'symbol)

(defun my-set-theme (appearance)
  (let ((theme (if (eq appearance 'light) my-light-theme my-dark-theme)))
    (dolist (enabled-theme custom-enabled-themes)
      (disable-theme enabled-theme))
    (load-theme theme t)))

(use-package modus-themes
  :custom
  (modus-themes-italic-constructs t)
  (modus-themes-org-blocks 'gray-background)
  :config
  (setq my-dark-theme 'modus-vivendi)
  (setq my-light-theme 'modus-operandi)
  (let ((modus-palette (append (seq-filter
                                (lambda (x)
                                  (let ((selector (car x)))
                                    (cond
                                     ((eq selector 'fringe) nil)
                                     (t 't))))
                                modus-themes-preset-overrides-intense)
                               '((fringe bg-dim)))))
    (setq modus-themes-common-palette-overrides modus-palette))
  (my-set-theme 'dark))

(use-package alert
  :custom (alert-default-style 'osx-notifier))

(use-package org-modern)

(use-package org
  :straight nil
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
  (org-hide-emphasis-markers t)
  (org-src-fontify-natively t)
  (org-fontify-quote-and-verse-blocks t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 2)
  (org-hide-block-startup nil)
  (org-src-preserve-indentation nil)
  (org-startup-folded 'content)
  (org-cycle-separator-lines 2)
  (org-capture-bookmarkk nil)
  :hook (org-mode . my-org-mode-setup)
  :init
  (defun my-org-mode-setup ()
    ;; (org-indent-mode)
    (auto-fill-mode 0)
    (visual-line-mode 1))
  :config
  (require 'org-tempo)
  ;; (require 'ox-latex)

  (setq org-agenda-files '(
                           ;; "~/doc/agendas"
                           "~/Documents"))

  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("li" . "src lisp"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("go" . "src go"))
  (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
  (add-to-list 'org-structure-template-alist '("json" . "src json")))

(use-package my-modeline
  :straight nil
  :config
  (setq-default mode-line-format my-modeline-format))

(use-package persp-mode
  ;; :after magit
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

  (defun persp-buffer-menu ()
    (interactive)
    (with-persp-buffer-list () (buffer-menu)))

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

(use-package reformatter
  :init
  (reformatter-define black-format
    :program "black"
    :args '("-")))

(use-package aggressive-indent)

(add-hook 'prog-mode-hook #'electric-indent-mode)

(setq tramp-default-method "ssh")

(setq-default indent-tabs-mode nil)

(use-package evil-commentary
  :init
  (evil-commentary-mode))

(setq-default show-trailing-whitespace t)

(use-package emacs
  :hook ((prog-mode cider-repl-mode) . electric-pair-local-mode))

(use-package lispyville
  :hook ((lisp-mode
          emacs-lisp-mode
          ielm-mode
          scheme-mode
          racket-mode
          hy-mode
          lfe-mode
          dune-mode
          clojure-mode
          cider-repl-mode
          fennel-mode)
         . lispyville-mode)
  :config
  (lispyville-set-key-theme '(operators slurp/barf-lispy c-w additional text-objects commentary)))

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
  :hook (((prog-mode eshell-mode cider-repl-mode) . corfu-mode)
         (corfu-mode . corfu-popupinfo-mode)
         (minibuffer-setup . corfu-enable-in-minibuffer))
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-popupinfo-delay '(1.0 . 0.5))
  (corfu-auto-delay 0)
  (corfu-auto-prefix 3)
  (corfu-quit-no-match 'separator)
  (corfu-preselect 'prompt)
  (corfu-preview-current 'insert)
  :general
  (:keymaps 'corfu-map
            "C-s" 'corfu-quit
            "<tab>" 'corfu-next
            "<backtab>" 'corfu-previous))

(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-use-icons nil)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file))

(use-package orderless
  :custom
  (completion-styles '(orderless-fast basic))
  (completion-category-overrides '((file (styles . (partial-completion)))))
  :config
  (defun orderless-fast-dispatch (word index total)
    (and (= index 0) (= total 1) (length< word 4)
         (cons 'orderless-literal-prefix word)))
  (orderless-define-completion-style orderless-fast
    (orderless-style-dispatchers '(orderless-fast-dispatch))
    (orderless-matching-styles '(orderless-literal orderless-regexp))))

(use-package consult
  :after persp-mode
  :config
  (consult-customize consult--source-buffer :hidden t :default nil)

  (defvar consult--source-perspective
    (list :name     "Persp Buffers"
          :narrow   ?s
          :category 'buffer
          :state    #'consult--buffer-state
          :default  t
          :items    (lambda () (seq-map #'buffer-name (persp-buffer-list)))))

  (push consult--source-perspective consult-buffer-sources)
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

;;; Languages

(use-package scad-mode)

(use-package markdown-mode)

(use-package rust-mode)

(use-package yuck-mode)

(use-package sly)

(use-package clojure-mode)

(use-package cider
  :hook (clojure-mode . cider-mode)
  :custom
  (cider-clojure-cli-global-options "-Adev")
  (cider-completion-annotations-include-ns 'always)
  (cider-repl-display-help-banner nil)
  (cider-eval-result-duration 'change)
  (cider-repl-pop-to-buffer-on-connect 'display-only)
  (cider-xref-fn-depth -100)
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
    "J" '(cider-jack-in-cljs :which-key "Jack-in cljs"))
  :config
  (add-to-list 'display-buffer-alist '("\\*cider-repl.*"
                                       (display-buffer-in-side-window)
                                       (window-height  . 0.20)
                                       (preserve-size . (nil . t)))))

(use-package jarchive
  :hook (clojure-mode . jarchive-mode))

(use-package nix-mode)

(use-package lua-mode)

(use-package haskell-mode)

(use-package scala-mode)

(use-package go-mode)

(use-package typescript-mode
  :custom
  (typescript-indent-level 2))

(use-package yaml-mode)

(use-package dockerfile-mode)

;;;; Tools

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :custom
  (pdf-view-display-size 'fit-width)
  (pdf-view-use-scaling t)
  (pdf-view-use-imagemagick nil))

(use-package pdf-view-restore
  :after pdf-tools
  :hook (pdf-view-mode . pdf-view-restore-mode))

(use-package emms
  :general
  (general-leader
    "o m" 'emms-smart-browse)
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
  (magit-diff-refine-hunk 'all)
  :general
  (general-leader
    "g" '(:ignore t :which-key "Git")
    "gg" '(magit :which-key "Magit"))
  :init
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

(use-package xref
  :config
  (add-to-list 'display-buffer-alist '("\\*xref\\*"
                                       (display-buffer-in-side-window)
                                       (window-height  . 0.20)
                                       (preserve-size . (nil . t)))))
(use-package eldoc
  :config
  (add-to-list 'display-buffer-alist '("\\*eldoc\\*"
                                       (display-buffer-in-side-window)
                                       (window-height  . 0.20)
                                       (preserve-size . (nil . t)))))

(use-package eglot
  :hook (((clojure-mode
           clojurescript-mode
           go-mode
           c-mode
           python-mode)
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
  (add-hook 'go-mode-hook (lambda ()
                            (add-hook 'before-save-hook
                                      (lambda ()
                                        (eglot-code-action-organize-imports (point-min)))
                                      nil t)))
  (defun my-eglot-lower-capf-prio ()
    "Make the eglot capf have lower priority"
    (when (boundp 'cider-mode)
      (when cider-mode
        (remove-from-list completion-at-point-functions t)
        (remove-from-list completion-at-point-functions #'eglot-completion-at-point)
        (add-to-list 'completion-at-point-functions #'eglot-completion-at-point t)
        (add-to-list 'completion-at-point-functions t t)))))

(use-package breadcrumb
  :hook (eglot-managed-mode . breadcrumb-local-mode))

(use-package dape
  :init
  (setq dape-buffer-window-arrangement 'left)
  :general
  (general-local-leader
    "d" '(nil :which-key "Dape")
    "dr" '(dape-restart :which-key "Restart")
    "dt" '(dape-breakpoint-toggle :which-key "Toggle breakpoint")
    "dl" '(dape-breakpoint-log :which-key "Log breakpoint"))
  :config
  (add-to-list 'dape-configs
               '(debugpy-attach-port
                 modes (python-mode python-ts-mode)
                 port  (lambda () (read-number "Port: " 5679))
                 ;; command "python"
                 ;; command-args ("-m" "debugpy.adapter")
                 :request "attach"
                 :type "python"
                 :justMyCode nil
                 :showReturnValue t)))


(use-package sideline-flymake
  :custom
  (sideline-flymake-display-mode 'line))

(use-package sideline
  :hook (flymake-mode . sideline-mode)
  :custom
  (sideline-backends-right '(sideline-flymake)))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode))

(use-package eat
  :hook (eshell-load . eat-eshell-mode))
