

(setq-default inhibit-startup-screen t;skip startup screen
              initial-scratch-message nil
              confirm-kill-emacs 'y-or-n-p;fuck typing yes/no
              frame-title-format '(buffer-file-name "%f" "%b") ; Useful file naming
              mode-line-format '(" %+ "                       ; Simplify the mode line
                                 (:propertize "%b" face mode-line-buffer-id)
                                 ":%l:%c %[" mode-name "%]"
                                 (-2 "%n")
                                 (visual-line-mode " W")
                                 (auto-fill-function " F")
                                 (overwrite-mode " O"))
              max-mini-window-height 1
              truncate-lines t;Don't wrap
              default-truncate-lines t
              vc-make-backup-files t;Backups in ~/.saves
              version-control t
              delete-old-versions t
              kept-new-versions 4
              kept-old-versions 0
              backup-directory-alist '((".*" . "~/.saves/"))
              auto-save-list-file-prefix nil
              auto-save-file-name-transforms '((".*" "~/.saves/" t))
              font-lock-use-fonts '(or (mono) (grayscale));More syntax highlighting
              font-lock-use-colors '(color)
              font-lock-maximum-decoration t
              font-lock-maximum-size nil
              font-lock-auto-fontify t
              show-paren-style 'expression;Highlight prins
              comment-empty-lines t;Prefix empty lines
              show-trailing-whitespace t
              use-dialog-box nil;Use minibuffer
              user-full-name "Benjamin Felber"
              display-warning-minimum-level 'error;Disable trivial errors
              disabled-command-function nil;Disable trivial corrections
              column-number-mode t;line/column numbers
              line-number-mode t
              tab-width 4
              tab-stop-list (number-sequence 4 120 4)
              indent-tabs-mode nil;NO TAB SPACING
              tabify-regexp "^\t* [ \t]+";Tabify whitespace
              page-delimiter "^\\s *\n";Set delimiter for 1+ blank line
              minibuffer-max-depth nil
              toolbar-print-function 'ps-print-buffer-with-faces;Print all nice
              ps-line-number t
              ps-n-up-printing 2
              ps-print-color-p nil
              fill-column 227;Wrap on 80 columns
              initial-major-mode 'text-mode;as opposed to elisp
              case-fold-search t
              buffers-menu-sort-function 'sort-buffers-menu-by-mode-then-alphabetically
              buffers-menu-grouping-function 'group-buffers-menu-by-mode-then-alphabetically
              buffers-menu-submenus-for-groups-p t
              ibuffer-default-sorting-mode 'filename/process;Group buffers
                                                            ;by dir
              uniquify-buffer-name-style 'forward;Prepend dir name to
                                                 ;resolve name conflicts
              uniquify-after-kill-buffer-p t
              uniquify-ignore-buffers-re "^\\*"
              major-mode 'major-mode-from-name
              ispell-program-name "aspell"
              ispell-dictionary "english"
              ediff-split-window-function 'split-window-horizontally;side
                                                                ;by side diffs
              diff-switches "-u" ;Prefer unified diffs
              org-support-shift-select t
              calc-display-sci-low -5;More sig figs
              )
(set-scroll-bar-mode 'right)
(set-fringe-mode '(1 . 0));Left fringe
(defun major-mode-from-name ()
  "Choose proper mode for buffers created by switch-to-buffer."
  (let ((buffer-file-name (or buffer-file-name (buffer-name))))
    (set-auto-mode)))
(show-paren-mode t);Highlight prins
(delete-selection-mode t);Replace selections by typing
(global-subword-mode t);Split camelcase into words
(auto-fill-mode t);Auto-wrap lines
(fset 'yes-or-no-p 'y-or-n-p);again, fuck typing yes or no
(require 'uniquify);Rename buffers on clashes
(require 'server);Attach to client
(if (not (server-running-p))
    (server-start));if it exists, else boot it
(set-default-font "Terminus-9");Set font to terminus
;Define custom window behavior
;(load-theme 'sanityinc-tomorrow-night t)
;Toggle UI elements if not in noX (within terminal)
(defun toggle-minimal-mode (fs)
  (interactive "P")
  (defun fullscreen-margins nil
    (if (and (window-full-width-p) (not (minibufferp)))
        (set-window-margins nil (/ (- (frame-width) 120) 2) (/ (- (frame-width) 120) 2))
      (mapcar (lambda (window) (set-window-margins window nil nil)) (window-list))))

  (cond (menu-bar-mode
         (menu-bar-mode -1) (tool-bar-mode -1) (scroll-bar-mode -1)
         (set-frame-height nil (+ (frame-height) 4))
         (if fs (progn (x-send-client-message nil 0 nil "_NET_WM_STATE" 32
                                              '(1 "_NET_WM_STATE_FULLSCREEN" 0))
                       (add-hook 'window-configuration-change-hook 'fullscreen-margins))))
        (t (menu-bar-mode 1) (tool-bar-mode 1) (scroll-bar-mode 1)
           (when (frame-parameter nil 'fullscreen)
             (remove-hook 'window-configuration-change-hook 'fullscreen-margins)
             (x-send-client-message nil 0 nil "_NET_WM_STATE" 32
                                    '(0 "_NET_WM_STATE_FULLSCREEN" 0))
             (set-window-buffer (selected-window) (current-buffer)))
           (set-frame-width nil (assoc-default 'width default-frame-alist)))))

(global-set-key [f11] 'toggle-minimal-mode)
;Set fullscreen and without GUI by default
(toggle-frame-maximized)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;Fix broken input because tmux/urxvt jank
(global-set-key "\M-[1;5C"    'forward-word)  ; Ctrl+right   => forward word
(global-set-key "\M-[1;5D"    'backward-word) ; Ctrl+left    =>backward words
;Ido mode
(require 'ido)
(ido-mode 1)
(add-hook 'find-file-hook 'ido-remember-buffer-file)
(defun ido-remember-buffer-file ()
  "Add buffer's file to ido cache/history"
  (interactive)
  (let ((file (expand-file-name (buffer-file-name))))
    (if file
        (let ((dir (file-name-directory file))
              (name (file-name-nondirectory file)))
          (ido-record-work-file name)
          (ido-record-work-directory dir)
          (ido-file-name-all-completions dir)))))
(ido-everywhere 1)
(defadvice completing-read
  (around use-ido-when-possible activate)
  (if (not (boundp 'ido-cur-list))
      (let ((completions (all-completions "" collection predicate)))
        (if completions
            (setq ad-return-value
                  (ido-completing-read prompt completions nil require-match
                                       initial-input hist def)))))
  (unless ad-return-value
    ad-do-it))
(define-key global-map [(meta ?x)] 'ido-meta-x)
(defun ido-meta-x ()
  "Replacement for standard M-x that use ido."
  (interactive)
  (call-interactively
   (intern
    (or (completing-read "M-x " (all-completions "" obarray 'commandp))))))

;Modded isearch
(defvar saved-which-function)
(add-hook 'isearch-mode-hook 'isearch-mode-start-which-func)
(defun isearch-mode-start-which-func ()
  "Start which-func mode and add it to the mode line."
  (setq saved-which-function which-function-mode)
  (nconc mode-line-format '((which-func-mode
                             (:propertize (" " which-func-current "()")
                                          face mode-line-emphasis))))
  (which-function-mode))
(add-hook 'isearch-mode-end-hook 'isearch-mode-end-which-func)
(defun isearch-mode-end-which-func ()
  "Stop which-func mode and clear it from the mode line."
  (which-function-mode (if saved-which-function 1 -1))
  (nbutlast mode-line-format))

;Basic text-mode settings
(add-hook 'text-mode-hook 'common-mode-setup)
(add-hook 'prog-mode-hook 'common-mode-setup)
(defun common-mode-setup ()
  "Automatically fill text by default."
  (auto-fill-mode t))
;Packages
(require 'package)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("marmalade" . "https://marmalade-repo.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")))
(package-initialize)
;Show line numbers when going to line
(global-set-key [remap goto-line] 'goto-line-with-feedback)
(defun goto-line-with-feedback ()
  "Show line numbers temporarily, while prompting for the line number input"
  (interactive)
  (unwind-protect
      (progn
        (linum-mode 1)
        (goto-line (read-number "Goto line: ")))
    (linum-mode -1)))
;Load-path
(add-to-list 'load-path "~/.emacs.d/lisp")
(add-to-list 'load-path "~/go/src/github.com/dougm/goflymake")

;Org-mode
(require 'org)
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)
(setq org-agenda-files (list "~/org/school.org"
                             "~/org/test.org"))
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "firefox-developer");fix links opening in wrong browser from org-mode
;Go/Go-mode
(require 'go-mode-load)
(defun custom-go-mode-hook ()
  (add-hook 'before-save-hook 'gofmt-before-save)
  (setq gofmt-command "goimports")
  (local-set-key (kbd "M-.") 'godef-jump)
  (local-set-key (kbd "C-c C-r") 'go-remove-unused-imports)
  )
(add-hook 'go-mode-hook 'custom-go-mode-hook)
(require 'go-flymake)


(require 'go-autocomplete)
(require 'auto-complete-config)
(ac-config-default)
(global-auto-complete-mode t)
;YAsnippet
(require 'yasnippet)
;(setq yas-snippet-dirs "~/.emacs.d/snippets")
(yas-global-mode t)
;remove default keybinds
;(define-key yas-minor-mode-map (kbd "<tab>") nil)
;(define-key yas-minor-mode-map (kbd "TAB") nil)
;(define-key yas-minor-mode-map (kbd "<backtab>") 'yas-expand)

 ;LaTeX setup
(load "auctex.el" nil t t)
(load "preview-latex.el" nil t t)
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)
(setq TeX-PDF-mode t)
(add-hook 'TeX-mode-hook 'flyspell-mode); Highlights all misspelled words.
(add-hook 'emacs-lisp-mode-hook 'flyspell-prog-mode); Enable Flyspell program mode for emacs lisp mode, which highlights all misspelled words in comments and strings.
(add-hook 'TeX-mode-hook
          (lambda () (TeX-fold-mode 1)))
(add-hook 'Tex-mode-hook 'LaTeX-math-mode)
;Subword-mode left/right
(define-key global-map [remap left-word] 'subword-left)
(define-key global-map [remap right-word] 'subword-right)
(defun subword-left (&optional n)
  "Move point N subwords to the left (to the right if N is
negative).  This behaves just like left-word, but uses subword
motion instead of regular word motion."
  (interactive "^p")
  (if (eq (current-bidi-paragraph-direction) 'left-to-right)
      (subword-backward n)
    (subword-forward n)))
(defun subword-right (&optional n)
  "Move point N subwords to the right (to the left if N is
negative).  This behaves just like right-word, but uses subword
motion instead of regular word motion."
  (interactive "^p")
  (if (eq (current-bidi-paragraph-direction) 'left-to-right)
      (subword-forward n)
    (subword-backward n)))
;Ido cleanup
(defun ido-really-wash-history ()
  "Remove non-local or non-existent entries from ido-mode's history and cache."
  (interactive)
  (ido-wash-history)
  (setq ido-last-directory-list
        (delq nil (mapcar
                   (lambda (entry)
                     (if (and (ido-local-file-exists-p (car entry))
                              (file-directory-p (concat (car entry) (cdr entry))))
                         entry))
                   ido-last-directory-list)))
  (setq ido-work-directory-list
        (delq nil (mapcar
                   (lambda (entry)
                     (if (and (ido-local-file-exists-p entry)
                              (file-directory-p entry))
                         entry))
                   ido-work-directory-list)))
  (mapc 'ido-file-name-all-completions
        (mapcar 'car ido-dir-file-cache)))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes (quote (sanityinc-tomorrow-night)))
 '(custom-safe-themes
   (quote
    ("06f0b439b62164c6f8f84fdda32b62fb50b6d00e8b01c2208e55543a6337433a" "4aee8551b53a43a883cb0b7f3255d6859d766b6c5e14bcb01bed572fcbef4328" "628278136f88aa1a151bb2d6c8a86bf2b7631fbea5f0f76cba2a0079cd910f7d" "05c3bc4eb1219953a4f182e10de1f7466d28987f48d647c01f1f0037ff35ab9a" "6a9606327ecca6e772fba6ef46137d129e6d1888dcfc65d0b9b27a7a00a4af20" "8db4b03b9ae654d4a57804286eb3e332725c84d7cdab38463cb6b97d5762ad26" "1e7e097ec8cb1f8c3a912d7e1e0331caeed49fef6cff220be63bd2a6ba4cc365" "b7d8113de2f7d9a3cf42335d8eed8415b5a417e7f6382e59076f9f4ae4fa4cee" "fc5fcb6f1f1c1bc01305694c59a1a861b008c534cae8d0e48e4d5e81ad718bc6" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 '(minimap-recenter-type (quote relative)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(minimap-font-face ((t (:height 3 :family "gohu-font"))))
 '(show-paren-match ((t (:foreground "#1d1f21")))))
