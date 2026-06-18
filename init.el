;; -*- lexical-binding: t; -*-

(defgroup cas-emacs nil
  "General options for my dot Emacs.")

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

(mapc
 (lambda (string)
   (add-to-list 'load-path (expand-file-name (locate-user-emacs-file string))))
 '("lisp" "modules"))

(setq user-emacs-directory (expand-file-name "~/.cache/emacs/"))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Elpaca

(require 'cas-emacs-elpaca)

;; Load packages early

(add-hook 'elpaca-after-init-hook (lambda () (load custom-file t)))

(use-package compat :ensure (:wait t))

(require 'cas-emacs-evil)

(use-package no-littering
  :ensure (:wait t)
  :init
  (require 'no-littering))

(setq elisp-flymake-byte-compile-load-path load-path)

(use-package dired
  :ensure nil
  :custom
  (dired-use-ls-dired nil)
  (dired-listing-switches "-alh --time-style=long-iso")
  :config
  (when (eq system-type 'darwin)
    (setq insert-directory-program "/opt/homebrew/bin/gls")))

;; Garbage collector
(use-package gcmh
  :init
  (gcmh-mode))

(use-package exec-path-from-shell
  :init
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; Functions

(defun cas-emacs-hide-trailing-whitespace ()
  "Hide trailing whitespace."
  (interactive)
  (setq-local show-trailing-whitespace nil))

(defun casmacs-open-in-finder (filename &optional _)
  (interactive
   (find-file-read-args "Open: " (confirm-nonexistent-file-or-buffer)))
  (start-process "finder" nil "open" (expand-file-name filename)))

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

(use-package which-key
  :custom
  (which-key-idle-delay 1)
  :init
  (which-key-mode))

(use-package emacs
  :ensure nil
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

    "o" '(nil :which-key "Open")
    "op" '(nil :which-key "Profiler")
    "ops" '(profiler-start :which-key "Profiler start")
    "opk" '(profiler-stop :which-key "Profiler stop")
    "opr" '(profiler-report :which-key "Profiler report")
    "p" '(nil :which-key "Project")
    "pf" '(project-find-file :which-key "Project find file")
    "qK" '(save-buffers-kill-emacs :which-key "Apps")
    "s" '(nil :which-key "Search")))

(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
;; (tooltip-mode -1)
(fringe-mode '(nil . 0))
(menu-bar-mode -1)

;; (if (not (eq system-type 'darwin))
;;     (menu-bar-mode -1))

(blink-cursor-mode 0)
(set-default 'truncate-lines t)

(use-package diff-hl
  :after magit
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init
  ;; (define-fringe-bitmap 'casmacs-diff-hl-bitmap [] 5 1 '(top t))
  ;; (setq diff-hl-fringe-bmp-function (lambda (type pos) 'casmacs-diff-hl-bitmap))
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
                conf-mode-hook
                html-mode-hook))
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
  (setq mac-pass-command-to-system nil
        mac-command-modifier 'control
        mac-right-command-modifier 'control
        mac-option-modifier 'meta
        mac-right-option-modifier 'none
        mac-control-modifier 'super
        mac-function-modifier 'hyper))

(use-package fontaine
  :custom
  (fontaine-latest-state-file (locate-user-emacs-file "fontaine-latest-state.eld"))
  (fontaine-presets '((regular :default-height 120)
                      (big :default-height 180)
                      (t :default-family "Go Mono")))
  :config
  (fontaine-set-preset (or (fontaine-restore-latest-preset) 'regular))
  :init
  (fontaine-mode))

(use-package alert
  :custom (alert-default-style 'osx-notifier))

;; (use-package org-modern)

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
  :hook (org-mode . casmacs-org-mode-setup)
  :init
  (defun casmacs-org-mode-setup ()
    ;; (org-indent-mode)
    (auto-fill-mode 0)
    (visual-line-mode 1))
  :config
  (require 'org-tempo)
  (setq org-agenda-files '("~/Documents"))

  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("li" . "src lisp"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("go" . "src go"))
  (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
  (add-to-list 'org-structure-template-alist '("json" . "src json")))

(use-package emacs
  :ensure nil
  :init
  (show-paren-mode))

(use-package reformatter
  :init
  (reformatter-define black-format
    :program "black"
    :args '("-")))

(use-package aggressive-indent)

(add-hook 'prog-mode-hook #'electric-indent-mode)

(use-package emacs
  :ensure nil
  :hook ((prog-mode html-mode cider-repl-mode) . electric-pair-local-mode))

(setq tramp-default-method "ssh")

(setq-default indent-tabs-mode nil)

(use-package evil-commentary
  :init
  (evil-commentary-mode))

(setq-default show-trailing-whitespace t)

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


(use-package emacs
  :ensure nil
  :custom
  (history-length 100)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (tab-always-indent 'complete)
  :init
  (savehist-mode 1))

(use-package emacs
  :ensure nil
  :custom
  (global-auto-revert-non-file-buffers t)
  :init
  (global-auto-revert-mode))

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

(use-package transient)

(use-package magit
  :hook (git-commit-mode . evil-insert-state)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  (transient-display-buffer-action '(display-buffer-below-selected))
  (magit-diff-refine-hunk 'all)
  :general
  (general-leader
    "g" '(:ignore t :which-key "Git")
    "gg" '(magit :which-key "Magit")))

;; (use-package git-link
;;   :custom
;;   (git-link-open-in-browser t))

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
  :custom
  (eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)
  :config
  (add-to-list 'display-buffer-alist '("\\*eldoc\\*"
                                       (display-buffer-in-side-window)
                                       (window-height  . 0.20)
                                       (preserve-size . (nil . t)))))

(use-package project
  :ensure nil
  :custom
  (project-prompter #'project-prompt-project-name)
  (project-vc-extra-root-markers '(".project" ".projectile")))

(use-package eglot
  :ensure nil
  :hook
  (((clojure-mode
     clojurescript-mode
     go-mode
     c-mode
     python-mode)
    .
    eglot-ensure)
   (eglot-managed-mode . casmacs-eglot-lower-capf-prio))
  :custom
  (eglot-confirm-server-initiated-edits nil)
  (max-mini-window-height 2)
  (eglot-code-action-indicator "✓")
  (eglot-report-progress nil)
  (eglot-connect-timeout 240)
  :general
  (general-local-leader
    :keymaps 'eglot-mode-map
    "c" '(nil :which-key "Eglot")
    "cc" '(eglot-code-actions :which-key "Code Actions")
    "cr" '(eglot-rename :which-key "Rename")
    "cf" '(eglot-format :which-key "Format"))
  :init
  (defun casmacs-eglot-lower-capf-prio ()
    "Make the eglot capf have lower priority"
    (when (boundp 'cider-mode)
      (when cider-mode
        (remove-from-list completion-at-point-functions t)
        (remove-from-list completion-at-point-functions #'eglot-completion-at-point)
        (add-to-list 'completion-at-point-functions #'eglot-completion-at-point t)
        (add-to-list 'completion-at-point-functions t t))))
  :config
  ;; (advice-add #'eglot-completion-at-point :around #'cape-wrap-buster)
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 "basedpyright-langserver" "--stdio"))
  (setq-default
   eglot-workspace-configuration
   '(:basedpyright
     (:typeCheckingMode "standard"))))


(use-package breadcrumb
  :hook (eglot-managed-mode . breadcrumb-local-mode))

(use-package dape
  :init
  (setq dape-buffer-window-arrangement 'left)
  :general
  (general-local-leader
    "d" '(nil :which-key "debug")
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
  :after sideline
  :custom
  (sideline-flymake-display-mode 'line))

(use-package sideline
  :hook (flymake-mode . sideline-mode)
  :custom
  (sideline-backends-right '(sideline-flymake)))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode))

(use-package eat
  :hook ((eshell-load . eat-eshell-mode)
         (eat-mode . cas-emacs--eat-font-setup)
         (eat-mode . cas-emacs-hide-trailing-whitespace))
  :preface
  (defun cas-emacs--eat-font-setup ()
    "Configure font settings specifically for vterm buffers, workaround claude-code."
    (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
      (dolist (pair
               '((#x273B . ?*)   ; ✻ TEARDROP-SPOKED ASTERISK
                 (#x273D . ?*)   ; ✽ HEAVY TEARDROP-SPOKED ASTERISK
                 (#x2722 . ?+)   ; ✢ FOUR TEARDROP-SPOKED ASTERISK
                 (#x2736 . ?+)   ; ✶ SIX-POINTED BLACK STAR
                 (#x2733 . ?*))) ; ✳ EIGHT SPOKED ASTERISK
        (aset tbl (car pair) (vector (cdr pair))))))
  )

(use-package ediff
  :ensure nil
  :custom
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  (ediff-keep-variants nil)
  (ediff-split-window-function #'split-window-horizontallly))

(use-package envrc
  :hook ((elpaca-after-init . envrc-global-mode)
         (envrc-global-mode
          .
          (lambda ()
            (let ((fn (if (fboundp #'envrc-global-mode-enable-in-buffers)
                          #'envrc-global-mode-enable-in-buffers ; Removed in Emacs 30.
                        #'envrc-global-mode-enable-in-buffer)))
              (if (not envrc-global-mode)
                  (remove-hook 'change-major-mode-after-body-hook fn)
                (remove-hook 'after-change-major-mode-hook fn)
                (add-hook 'change-major-mode-after-body-hook fn 100)))))))

(use-package inheritenv
  :config
  ;; CIDER starts the nREPL server inside a fresh *nrepl-server* buffer, which
  ;; lacks envrc's buffer-local environment, so the JVM misses `.envrc'. Wrap the
  ;; jack-in commands so they inherit the env from the buffer they're invoked in.
  (with-eval-after-load 'cider
    (inheritenv-add-advice #'cider-jack-in-clj)
    (inheritenv-add-advice #'cider-jack-in-cljs)))

(use-package vterm
  :hook ((vterm-mode . cas-emacs-hide-trailing-whitespace)
         (vterm-mode . cas-emacs--vterm-font-setup))
  :preface
  (defun cas-emacs--vterm-font-setup ()
    "Configure font settings specifically for vterm buffers, workaround claude-code."
    (let ((tbl (or buffer-display-table (setq buffer-display-table (make-display-table)))))
      (dolist (pair
               '((#x273B . ?*)   ; ✻ TEARDROP-SPOKED ASTERISK
                 (#x273D . ?*)   ; ✽ HEAVY TEARDROP-SPOKED ASTERISK
                 (#x2722 . ?+)   ; ✢ FOUR TEARDROP-SPOKED ASTERISK
                 (#x2736 . ?+)   ; ✶ SIX-POINTED BLACK STAR
                 (#x2733 . ?*)   ; ✳ EIGHT SPOKED ASTERISK
                 (#x23FA . ?●))) ; ⏺ BLACK CIRCLE FOR RECORD
        (aset tbl (car pair) (vector (cdr pair)))))))


(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :general
  (general-leader
    "occ" '(claude-code-ide-toggle :which-key "toggle claude ide")
    "ocm" '(claude-code-ide-menu :which-key "claude ide menu")
    "ocs" '(claude-code-ide :which-key "start claude code ide"))
  :custom
  (claude-code-ide-terminal-backend 'vterm)
  :config
  (inheritenv-add-advice 'claude-code-ide--create-terminal-session)
  (claude-code-ide-emacs-tools-setup))

;; (use-package treesit-auto
;;   :custom
;;   (treesit-auto-install 'prompt)
;;   :config
;;   (treesit-auto-add-to-auto-mode-alist 'all))

(use-package minions
  :config (minions-mode))

(require 'cas-emacs-langs)
(require 'cas-emacs-modeline)
(require 'cas-emacs-perspective)
(require 'cas-emacs-consult)
(require 'cas-emacs-theme)
(require 'cas-emacs-completion)

;; if something breaks before this, debug. This is set to 't on early-init
;; (setq debug-on-error nil)
