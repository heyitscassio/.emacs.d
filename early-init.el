;; -*- lexical-binding: t; -*-

(setq debug-on-error t)

;; Garbage Collections
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Compile warnings
(setq warning-minimum-level :emergency)
(setq native-comp-async-report-warnings-errors 'silent) ;; native-comp warning
;; (setq byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))

(setq package-native-compile t)
(setq native-comp-jit-compilation nil)

;; optimizations (froom Doom's core.el). See that file for descriptions.
(setq idle-update-delay 1.0)

;; Disabling bidi (bidirectional editing stuff)
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)  ; emacs 27 only - disables bidirectional parenthesis

(setq highlight-nonselected-windows nil)
(setq fast-but-imprecise-scrolling t)
(setq inhibit-compacting-font-caches t)

;; Data emacs reads from process
(setq read-process-output-max (* 1024 1024)) ;; 1mb

;; (setq package-enable-at-startup t)

;; Silence compiler warnings as they can be pretty disruptive
(setq native-comp-async-report-warnings-errors nil)

;; Set the right directory to store the native comp cache
;; (add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" user-emacs-directory))
