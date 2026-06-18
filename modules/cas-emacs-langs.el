;; -*- lexical-binding: t; -*-

;;; Arduino

(use-package arduino-mode)

;;; Clojure

(use-package clojure-mode
  :custom
  (clojure-cache-project-dir nil)
  (clojure-project-root-function #'cas--clojure-project-root-path-project)
  :config
  (defun cas--clojure-project-root-path-project (&optional dir-name)
    (if (project-current)
        (project-root (project-current))
      (clojure-project-root-path dir-name)))
  (put-clojure-indent 'defc 1))

(use-package cider
  :hook (clojure-mode . cider-mode)
  :custom
  (nrepl-sync-request-timeout nil)
  ;; (cider-clojure-cli-global-options "-Adev")
  (cider-clojure-cli-aliases ":dev")
  (cider-completion-annotations-include-ns 'always)
  (cider-repl-display-help-banner nil)
  (cider-eval-result-duration 'change)
  (cider-repl-pop-to-buffer-on-connect 'display-only)
  (cider-xref-fn-depth -100)
  (cider-offer-to-open-cljs-app-in-browser nil)
  :general
  (general-local-leader
    :keymaps 'clojure-mode-map
    "e" '(nil :which-key "eval")
    "eb" '(cider-eval-buffer :which-key "Eval buffer")
    "ed" '(cider-debug-defun-at-point :which-key "Eval debug")

    "t" '(nil :which-key "test")
    "ta" #'cider-test-rerun-test
    "tl" #'cider-test-run-loaded-tests
    "tn" #'cider-test-run-ns-tests
    "tp" #'cider-test-run-project-tests
    "tr" #'cider-test-rerun-failed-tests
    "ts" #'cider-test-run-ns-tests-with-filters
    "tt" #'cider-test-run-test
    "tf" #'cas-cider-find-test-file
    "tF" #'cas-cider-find-test-file-other-window

    "'" '(cider-connect-clj :which-key "Connect clj")
    "\"" '(cider-connect-cljs :which-key "Connect cljs")
    "j" '(cider-jack-in-clj :which-key "Jack-in clj")
    "J" '(cider-jack-in-cljs :which-key "Jack-in cljs")
    "q" '(cider-quit :which-key "Quit repl"))
  (general-local-leader
    :keymaps 'cider-repl-mode-map
    "q" '(cider-quit :which-key "Quit repl"))
  :config
  (add-to-list 'display-buffer-alist '("\\*cider-repl.*"
                                       (display-buffer-in-side-window)
                                       (window-height  . 0.20)
                                       (preserve-size . (nil . t))))
  :preface
  (defun cas-cider--toggle-test-ns (&optional other-window)
    "Jump to the toggled test/source namespace.
     If OTHER-WINDOW is non-nil, open in another window."
    (let* ((current-ns (cider-current-ns))
           (in-test-p (string-suffix-p "-test" current-ns))
           (target-ns (if in-test-p
                          (substring current-ns 0 (- (length current-ns) 5))
                        (concat current-ns "-test"))))
      (message "%s" target-ns)
      (condition-case nil
          (if other-window
              (let ((current-buffer (current-buffer)))
                (cider-find-ns nil target-ns)
                (let ((target-buffer (current-buffer)))
                  (switch-to-buffer current-buffer)
                  (switch-to-buffer-other-window target-buffer)))
            (cider-find-ns nil target-ns))
        (error (message "No namespace found: %s" target-ns)))))

  (defun cas-cider-find-test-file ()
    "Jump to test namespace, or back to source namespace if already in a test file."
    (interactive)
    (cas-cider--toggle-test-ns nil))

  (defun cas-cider-find-test-file-other-window ()
    "Like `cas-cider-find-test-file', but open in another window."
    (interactive)
    (cas-cider--toggle-test-ns t)))

;;; C

(use-package cc-mode
  :ensure nil
  :custom
  (c-tab-always-indent 'complete)
  (c-default-style '((c-mode . "k&r")
                     (c++-mode . "k&r")
                     (java-mode . "java")
                     (other . "gnu"))))

;;; Common Lisp

(use-package sly)

;;; Dockerfile

(use-package dockerfile-mode)

;;; Elisp

(use-package flymake
  :ensure nil
  :hook (emacs-lisp-mode . (lambda () (add-hook 'find-file-hook #'cas-emacs-flymake-mode-when-lexical-bound nil t)))
  :init
  (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake)
  :preface
  (defun cas-emacs-flymake-mode-when-lexical-bound ()
    (when lexical-binding
      (flymake-mode 1))))

;;; Elixir

;; (use-package elixir)

;;; Go

(use-package go-mode
  :hook (go-mode . (lambda () (setq tab-width 4))))

(use-package graphql-mode)

;;; Haskell

(use-package haskell-mode)

;;; Java

(use-package jarchive
  :hook (clojure-mode . jarchive-mode))

;;; Lua

(use-package lua-mode)

;;; Markdown

(use-package markdown-mode)

;;; Nix

(use-package nix-mode
  :mode "\\.nix\\'")

;;; Python

(use-package python
  :custom
  (python-indent-def-block-scale 1))

;;; Rust

(use-package rust-mode)

;;; Scad

(use-package scad-mode)

;;; Scala

(use-package scala-mode)

;;; Terraform

(use-package terraform-mode)

;;;

(use-package templ-ts-mode)

;;; Typescript

(use-package typescript-mode
  :custom
  (typescript-indent-level 2))

;;; Verilog

(use-package verilog-mode
  :custom
  (verilog-auto-newline nil))

(use-package verilog-ext)

;;; Vue

(use-package web-mode
  :mode ("\\.vue\\'" . vue-mode)
  :init
  (define-derived-mode vue-mode web-mode "Vue")
  (setq web-mode-script-padding 0
        web-mode-markup-indent-offset 2
        web-mode-code-indent-offset 2))

;;; Yaml

(use-package yaml-mode)

(provide 'cas-emacs-langs)

;;; Svelte

(use-package svelte-mode)
