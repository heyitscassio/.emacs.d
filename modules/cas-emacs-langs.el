;; -*- lexical-binding: t; -*-

;;; Clojure

(use-package clojure-mode
  :config
  (put-clojure-indent 'defc 1))

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

;;; Common Lisp

(use-package sly)

;;; Dockerfile

(use-package dockerfile-mode)

;;; Elisp

(use-package flymake
  :hook (emacs-lisp-mode . (lambda () (add-hook 'find-file-hook #'cas-emacs-flymake-mode-when-lexical-bound nil t)))
  :preface
  (defun cas-emacs-flymake-mode-when-lexical-bound ()
    (when lexical-binding
      (flymake-mode 1))))

;;; Elixir

(use-package elixir)

;;; Go

(use-package go-mode)

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

(use-package nix-mode)

;;; Rust

(use-package rust-mode)

;;; Scad

(use-package scad-mode)

;;; Scala

(use-package scala-mode)

;;; Typescript

(use-package typescript-mode
  :custom
  (typescript-indent-level 2))

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
