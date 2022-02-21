;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Artem Pelenitsyn"
      user-mail-address "a.pelenitsyn@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))
(setq doom-font
        (font-spec :family "monospace" :size 14 :weight 'medium)
      doom-variable-pitch-font
        (font-spec :family "Roboto" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Dropbox/Notes")
(setq org-roam-directory "~/Dropbox/Notes/memos")
(setq org-roam-capture-templates
      '(("d" "default" plain "%?"
         :target (file+head "%<%Y-%m-%d>-${slug}.org"
                            "#+title: ${title}\n")
         :unnarrowed t)))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Please, just quit
(setq confirm-kill-emacs nil)

;; Proof General window layout that makes most sense
(customize-set-variable 'proof-three-window-mode-policy 'hybrid)

;; SPC m v for preview latex
(map!
 :map LaTeX-mode-map
 :localleader
 :desc "View" "v" #'TeX-view)

;; recompile-on-save-mode
(defun compile-on-save-start ()
  (let ((buffer (compilation-find-buffer)))
    (unless (get-buffer-process buffer) 
      (recompile))))

(define-minor-mode compile-on-save-mode
  "Minor mode to automatically call `recompile' whenever the
current buffer is saved. When there is ongoing compilation,
nothing happens."
  :lighter " CoS"
    (if compile-on-save-mode
    (progn  (make-local-variable 'after-save-hook)
        (add-hook 'after-save-hook 'compile-on-save-start nil t))
      (kill-local-variable 'after-save-hook)))

(add-hook! latex-mode compile-on-save-mode)
;; (add-hook! csv-mode csv-align-mode)

;; relative numbers for evil
;; (setq display-line-numbers-type 'relative)

;; Set local leader to comma instead of SPC m (all hail Spacemacs!)
(add-hook! 'org-mode-hook #'+org-init-keybinds-h)
(setq evil-snipe-override-evil-repeat-keys nil)
(setq doom-localleader-key ",")
(setq doom-localleader-alt-key "M-,")

;; Agda mode doesn't auto-load in lagda.md files although it should!
(setq auto-mode-alist
   (append
     '(("\\.agda\\'" . agda2-mode)
       ("\\.lagda.md\\'" . agda2-mode))
     auto-mode-alist))

;; scroll to center when search with / and n
(advice-add 'evil-ex-search-next :after
            (lambda (&rest x) (evil-scroll-line-to-center (line-number-at-pos))))
(advice-add 'evil-ex-search-previous :after
            (lambda (&rest x) (evil-scroll-line-to-center (line-number-at-pos))))

;; Put this bloody 80 chars limit in place!
(add-hook 'text-mode-hook 'turn-on-auto-fill)

;; Come to the evil side even in minibuffers
(setq evil-want-minibuffer t)

;; Sane motions when soft-wrap is on (don't really work)
(use-package-hook! evil
  :pre-init
  (setq evil-respect-visual-line-mode t) ;; sane j and k behavior
  t)

;; too fast completion popup is annoying; Doom's default is 0.2
(after! company
  (setq company-idle-delay 0.8))

;; saner defaults for evil, thanks to:
;; https://tecosaur.github.io/emacs-config/config.html
(after! evil
  (setq evil-ex-substitute-global t     ; I like my s/../.. to be global by default
        evil-kill-on-visual-paste nil)) ; Don't put overwritten text in the kill ring

;; Mark the whole buffer using SPC b w
(map! :leader
      (:prefix "b"
       :desc "Mark the whole buffer" "w" #'mark-whole-buffer))

;; Julia: use our language server
(setq lsp-julia-package-dir nil)
(after! lsp-julia
  (setq lsp-julia-default-environment "~/.julia/environments/v1.7"))
;;; https://github.com/gdkrmr/lsp-julia/issues/23:
(setq lsp-enable-folding t)
(setq lsp-folding-range-limit 100)

;; ob-haskell (Org Babel for Haskell) breaks on custom prompts that I put in my .ghci
(after! haskell
        (setq! haskell-process-args-ghci '("-ferror-spans" "-ignore-dot-ghci")))

;; org mode: align tags to the right margin
(after! org
  (setq org-tags-column -100)
)

;; forge authentification
(after! forge
  (setq auth-sources '("~/.authinfo"))
)
