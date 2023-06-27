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

(setup-define :leader
  (lambda (&rest first)
    `(with-eval-after-load 'general
       (my/leader-key-def ,@first)))
  :documentation "Associate the current mode with files that match REGEXP."
  :debug '(form)
  ;; :repeatable
  :indent 1)

(setup (:pkg nix-mode)
  (:leader
      "ab" '(nil :which-key "toba")
      "cb" '(nil :which-key "toba")))

(my/leader-key-def
  "ab" '(nil :which-key "toba")
  "cb" '(nil :which-key "toba"))

;; Recipe is always a list
;; Install via Guix if length == 1 or :guix t is present

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

(setq inhibit-startup-message t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 10)
(menu-bar-mode -1)
(blink-cursor-mode 0)

;; (setup (:pkg all-the-icons)
;;   ;; (:option all-the-icons-scale-factor 2
;;   ;;          all-the-icons-wicon-scale-factor 2)
;;   )

(setup (:pkg diff-hl)
  (global-diff-hl-mode))

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
  (add-hook mode (lambda () (display-line-numbers-mode 1))))

;; Override some modes which derive from the above
(dolist (mode '(org-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq large-file-warning-threshold nil)
(setq vc-follow-symlinks t)
(setq ad-redefinition-action 'accept)
(defalias 'yes-or-no-p 'y-or-n-p)

(defvar ignored-buffers '("\\*Messages\\*"
                          "\\*straight-process\\*"
                          "\\*Help\\*"
                          "\\*Backtrace\\*"))

(defun my/ignore-buffers (buffers)
  (setq ignored-buffers (append ignored-buffers buffers)))

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
                                              evil-window-next))))
  (:load-after consult
    (add-hook 'consult-after-jump-hook #'pulsar-recenter-top)
    (add-hook 'consult-after-jump-hook #'pulsar-reveal-entry))
  (pulsar-global-mode))

(defun my/set-font-faces ()
  (if window-system
      (let* ((main-font "Iosevka Nerd Font Mono:pixelsize=21")
             (fallback "monospace")
             (font (if (x-list-fonts main-font) main-font fallback)))
        (set-face-attribute 'default nil :font font)
        (set-face-attribute 'fixed-pitch nil :font font))))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame (my/set-font-faces))))
  (my/set-font-faces))

(setup (:pkg modus-themes)
    (require-theme 'modus-themes)
    (setq modus-themes-org-blocks 'gray-background
	modus-themes-italic-constructs t)
    (load-theme 'modus-vivendi :no-confirm))

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
;;(setup (:package no-littering)
;;  (require 'no-littering))

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(setup (:pkg undo-tree)
  (setq undo-tree-auto-save-history nil)
  (global-undo-tree-mode 1))

(setup (:pkg evil)
  ;; Pre-load configuration
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  (setq evil-respect-visual-line-mode t)
  (setq evil-undo-system 'undo-tree)

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

  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(setup (:pkg evil-collection)
  ;; Is this a bug in evil-collection?
  (setq evil-collection-company-use-tng nil)
  (:load-after evil
    (:option evil-collection-outline-bind-tab-p nil
	     (remove evil-collection-mode-list) 'lispy
	     (remove evil-collection-mode-list) 'org-present)
    (evil-collection-init)))

(setup (:pkg evil-goggles)
  (:when-loaded
    (:option evil-goggles-pulse nil
             evil-goggles-enable-delete nil
             evil-goggles-enable-change nil
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

(setup (:pkg which-key)
  (diminish 'which-key-mode)
  (which-key-mode)
  (setq which-key-idle-delay 0.3))

(setup (:pkg general)
  (general-evil-setup t)

  (general-create-definer my/leader-key-def
    :states 'normal
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  (general-create-definer my/local-leader-key-def
    :states 'normal
    :prefix "SPC m"
    :global-prefix "C-SPC m")

  ;;(general-create-definer my/ctrl-c-keys
    ;;:prefix "C-c")

  (my/leader-key-def
    "b" '(nil :which-key "Buffers")
    "br" '(revert-buffer :which-key "revert buffer")
    "f" '(nil :which-key "Files")
    "ff" '(find-file :which-key "Ripgrep")

    "h" '(nil :which-key "Help")
    "hc" '(describe-char :which-key "Describe Char")
    "hC" '(describe-command :which-key "Describe Command")
    "he" '(view-echo-area-messages :which-key "Show Echo Area Messages")
    "hf" '(describe-function :which-key "Describe Function")
    "hF" '(describe-face :which-key "Describe Face")
    "hv" '(describe-variable :which-key "Describe Variable")

    "o" '(nil :which-key "Apps")
    "qK" '(save-buffers-kill-emacs :which-key "Apps")))

;; TODO: Mode this to another section
;; (setq-default fill-column 80)

;; Turn on indentation and auto-fill mode for Org files
(defun my/org-mode-setup ()
  (org-indent-mode)
  (auto-fill-mode 0)
  (visual-line-mode 1)
  (setq evil-auto-indent nil)
  (diminish org-indent-mode))

(setup (:pkg org)
  (:also-load org-tempo)
  (:hook my/org-mode-setup)
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

  ;; (setq org-modules
  ;;   '(org-crypt
  ;;     org-habit
  ;;     org-bookmark
  ;;     org-eshell
  ;;     org-irc))

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

(setq display-time-format "%l:%M %p %b %y"
      display-time-default-load-average nil)

(setup (:pkg nerd-icons))

(setup (:pkg minions)
  (:hook-into doom-modeline-mode))

(setup (:pkg doom-modeline)
  (:hook-into after-init-hook)
  (:option doom-modeline-height 33
           doom-modeline-bar-width 6
           doom-modeline-lsp t
           doom-modeline-github nil
           doom-modeline-mu4e nil
           ;; doom-modeline-irc t
           doom-modeline-buffer-state-icon nil
           doom-modeline-minor-modes t
           doom-modeline-modal-icon nil
           doom-modeline-persp-name nil
           doom-modeline-buffer-file-name-style 'truncate-except-project
           doom-modeline-major-mode-icon nil)
  (:load-after evil
    (setq evil-normal-state-tag ""
          evil-emacs-state-tag ""
          evil-insert-state-tag ""
          evil-motion-state-tag ""
          evil-visual-state-tag ""
          evil-operator-state-tag "")))

(setup (:pkg nyan-mode)
  (nyan-mode))

(setup (:pkg perspective)
  (:option persp-initial-frame-name "Main"
           persp-suppress-no-prefix-key-warning t)
  (my/leader-key-def
    "TAB" '(nil :which-key "Workspaces")
    "TAB l" '(persp-switch :which-key "Persp Switch")
    "TAB n" '(persp-next :which-key "Persp Next")
    "TAB p" '(persp-prev :which-key "Persp Previous"))
  (unless (equal persp-mode t)
    (persp-mode))
  (:load-after consult
    (consult-customize consult--source-buffer :hidden t :default nil)
    (add-to-list 'consult-buffer-sources persp-consult-source)))

(setq global-auto-revert-non-file-buffers t)

(setup (:require paren)
  (show-paren-mode 1))

(setq tramp-default-method "ssh")

(setq-default indent-tabs-mode nil)

(setup (:pkg evil-commentary)
  (evil-commentary-mode))

(setq-default show-trailing-whitespace t)

(setup (:pkg lispyville)
  (:hook-into lisp-mode-hook
              emacs-lisp-mode-hook
              clojure-mode-hook
              scheme-mode-hook)
  (lispyville-set-key-theme '(slurp/barf-lispy operators c-w additional commentary))
  (lispy-mode))

(add-hook 'prog-mode-hook
          (lambda ()
            (electric-pair-local-mode t)))

(add-hook 'cider-repl-mode-hook
          (lambda ()
            (electric-pair-local-mode t)))

(setup (:pkg origami)
  (:hook-into yaml-mode))

(setup (:pkg envrc)
  (my/ignore-buffers '("\\*envrc\\*"))
  (envrc-global-mode))

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
  (:hook-into prog-mode-hook)
  (:option corfu-cycle t
           corfu-auto t
           corfu-auto-delay 0.1
           corfu-auto-prefix 2
           corfu-quit-no-match nil
           corfu-preselect 'prompt)
  (defun corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer if `completion-at-point' is bound."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-in-minibuffer))

(setup (:pkg kind-icon)
  (:option kind-icon-default-face 'corfu-default)
  (:load-after corfu
    (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))
  (:when-loaded
    (plist-put kind-icon-default-style :height 0.833)))

(setup (:pkg orderless)
  (require 'orderless)
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles . (partial-completion))))))

(setup (:pkg consult)
  (:require consult)
  ;; (require 'consult)
  (my/leader-key-def
    "SPC" '(my/switch-buffer :which-key "Buffers")
    "/" '(consult-ripgrep :which-key "Ripgrep")
    "bb" '(my/project-buffer :which-key "Project Buffers"))

  (:with-map minibuffer-local-map
    (:bind "C-r" consult-history))

  (defun my/get-project-root ()
    (when (fboundp 'projectile-project-root)
      (projectile-project-root)))

  (defun my/switch-buffer ()
    (interactive)
    (let ((consult-buffer-filter (append consult-buffer-filter ignored-buffers)))
      (consult-buffer)))

  (defun my/project-buffer ()
    (interactive)
    (let ((consult-buffer-filter (append consult-buffer-filter ignored-buffers)))
      (consult-project-buffer)))

  (:option consult-project-root-function #'my/get-project-root
           completion-in-region-function #'consult-completion-in-region))

(setup (:pkg cider)
  (:option cider-clojure-cli-global-options "-Adev"
           cider-auto-mode nil)
  (my/local-leader-key-def
    :keymaps 'clojure-mode-map
    "e" '(nil :which-key "Eval")
    "eb" '(cider-eval-buffer :which-key "Eval buffer")
    "ed" '(cider-eval-defun-at-point :which-key "Eval debug")
    "'" '(cider-connect-clj :which-key "Connect clj")
    "\"" '(cider-connect-cljs :which-key "Connect cljs")
    "j" '(cider-jack-in-clj :which-key "Jack-in clj")
    "J" '(cider-jack-in-cljs :which-key "Jack-in cljs"))
  (add-to-list 'completion-category-defaults '(cider (styles basic)))
  (add-hook 'clojure-mode-hook #'cider-mode)
  (my/ignore-buffers '("\\*cider-repl.*")))

;; (setup (:pkg nix-mode)
;;   (:file-match "*.nix"))


(setup (:pkg nix-mode))

(setup (:pkg emms)
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
  (emms-standard)
  (emms-default-players)
  (setq emms-browser-covers #'emms-browser-cache-thumbnail-async)
  (emms-mode-line-disable)
  (setq emms-source-file-default-directory "/mnt/extern/music/")
  (advice-add 'emms-browser-format-line :override #'my-emms-browser-format-line)
  (my/leader-key-def
    :keymap 'override
    "o"  '(:ignore t :which-key "Open")
    "om" '(emms-smart-browse :which-key "play / pause")))

(setup (:pkg magit)
  (:option magit-display-buffer-function #'my/magit-buffer-function)
  (my/ignore-buffers '("^magit: .*"))

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
               nil))))
  (my/leader-key-def
    "g" '(:ignore t :which-key "Git")
    "gg" '(magit :which-key "Magit")))

(setup (:pkg eglot)
  (my/ignore-buffers '("^\\*EGLOT .*"))
  (:with-mode (clojure-mode go-mode)
    (:hook #'eglot-ensure)))
