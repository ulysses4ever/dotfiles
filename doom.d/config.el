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
        (font-spec :family "FiraCode Nerd Font" :size 15 :weight 'medium)
      doom-symbol-font
        (font-spec :family "FiraCode Nerd Font" :size 15 :weight 'medium)
      doom-variable-pitch-font
        (font-spec :family "Roboto" :size 14))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one-light)

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
;; (add-hook 'text-mode-hook 'turn-on-auto-fill)

;; Come to the evil side even in minibuffers
(setq evil-want-minibuffer t)

;; Sane motions when soft-wrap is on (don't really work)
(use-package-hook! evil
  :pre-init
  (setq evil-respect-visual-line-mode t) ;; sane j and k behavior
  t)
;; another try that actually works (not sure if it breaks some things)
(map! :n "j" #'evil-next-visual-line
      :n "k" #'evil-previous-visual-line
      :n "0" #'evil-beginning-of-visual-line
      :n "$" #'evil-end-of-visual-line)

(map! :n "C-i" "i ESC r" :desc "Insert a character without leaving the normal mode.")

;; too fast completion popup is annoying; Doom's default is 0.2
(after! company
  (setq company-idle-delay 0.5))

;; saner defaults for evil, thanks to:
;; https://tecosaur.github.io/emacs-config/config.html
(after! evil
  (setq evil-ex-substitute-global t     ; I like my s/../.. to be global by default
        evil-kill-on-visual-paste nil)) ; Don't put overwritten text in the kill ring

; Mark the whole buffer using SPC b w
(map! :leader
      (:prefix "b"
       :desc "Mark the whole buffer" "w" #'mark-whole-buffer))

;; Julia: use our language server
;; (setq lsp-julia-package-dir nil)
;; (after! lsp-julia
;;   (setq lsp-julia-default-environment "~/.julia/environments/v1.7"))
;;; https://github.com/gdkrmr/lsp-julia/issues/23:
(setq lsp-enable-folding t)
;; (setq lsp-folding-range-limit 100)

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

;; Moving over camelCase graciously
(global-subword-mode 1)

;; The emoji module turns on global-emojify-mode with the first buffer, and the
;; +github style needs an image set that emojify fetches on first use. Left at
;; its default ('ask) it asks with yes-or-no-p, which in the daemon -- before
;; any frame exists -- waits on a keyboard there isn't and wedges the whole
;; daemon. That surfaced moving to nix-doom-emacs-unstraightened, whose data
;; dir starts out empty. Fetch without asking: a failed download errors out
;; instead of hanging.
(after! emojify
  (setq emojify-download-emojis-p t))

;; jk stopped working suddenly in Spring 2025.
;; Trying to bring it back using the advice how to disable it:
;; https://discourse.doomemacs.org/t/59
(after! evil-escape
  (setq evil-escape-key-sequence "jk"))

;; pyret.el ships no autoload cookies, so its own `auto-mode-alist' entry never
;; fires until the package is loaded.
(use-package! pyret
  :mode ("\\.arr\\'" . pyret-mode)
  :config
  (defun +pyret-run ()
    "Run the current Pyret file's check blocks."
    (interactive)
    (save-buffer)
    ;; pyret drops a .pyret/ cache beside the file and resolves the compiled
    ;; output's requires from it, so it has to run in the file's directory.
    (let ((default-directory (file-name-directory buffer-file-name)))
      (compile (concat "pyret -q --checks all "
                       (shell-quote-argument
                        (file-name-nondirectory buffer-file-name))))))

  (map! :map pyret-mode-map :localleader "r" #'+pyret-run)

  (after! compile
    ;; Locations read `file://ABS/PATH:LINE:COL-LINE:COL', at the start of
    ;; check-result lines and mid-sentence in compile errors, so this cannot
    ;; anchor to the start of a line.
    (add-to-list 'compilation-error-regexp-alist-alist
                 '(pyret "file://\\(.+?\\):\\([0-9]+\\):\\([0-9]+\\)-[0-9]+:[0-9]+"
                         1 2 3))
    (add-to-list 'compilation-error-regexp-alist 'pyret)))

;; accept completion from copilot and fallback to company
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

(after! copilot-chat
  ;; Start a chat session
  (map! :leader
        :desc "Copilot Chat"
        "l C" #'copilot-chat)

  ;; Add current buffer as context
  (map! :leader
        :desc "Copilot Chat Add Current Buffer"
        "l a" #'copilot-chat-add-current-buffer)

  ;; Remove current buffer from context
  (map! :leader
        :desc "Copilot Chat Remove Current Buffer"
        "l r" #'copilot-chat-del-current-buffer)

  ;; List and manage context buffers
  (map! :leader
        :desc "Copilot Chat List Context Buffers"
        "l l" #'copilot-chat-list)

  ;; Go to input prompt in the chat buffer
  (map! :leader
        :desc "Copilot Chat Go To Input"
        "l g" #'copilot-chat-goto-input))

;; remove the pesky -k from the default compile command
(setq compile-command "make")
;; build latex with latexmk into _build directory by default
(add-hook! 'LaTeX-mode-hook :append (lambda ()
            (set (make-local-variable 'compile-command)
                 (format "latexmk -xelatex --output-directory=_build %s" (file-name-nondirectory buffer-file-name)))))

;; Set path to mermaid CLI (adjust the path if mmdc is not in your system's PATH)
(setq ob-mermaid-cli-path "mmdc")
;; Add mermaid to org-babel-load-languages
(org-babel-do-load-languages 'org-babel-load-languages '((mermaid . t)))

;; Outline sidebar (SPC o o): the imenu index that SPC s i shows in a popup,
;; kept in a persistent pane under treemacs' one in the same left column.
(use-package! imenu-list
  :defer t
  :init
  ;; imenu-list-smart-toggle closes the sidebar whenever it shows, so the way
  ;; into it was SPC w h. Here a press moves focus into an open sidebar, and
  ;; only a press from inside it closes it.
  (defun +outline/open-focus-or-close ()
    "Open the outline sidebar; if it is open, focus it; if focused, close it."
    (interactive)
    (require 'imenu-list)
    (let ((window (get-buffer-window imenu-list-buffer-name)))
      (cond ((null window) (imenu-list-minor-mode 1))
            ((eq window (selected-window)) (imenu-list-minor-mode -1))
            (t (select-window window)))))
  (map! :leader :desc "Outline sidebar" "o o" #'+outline/open-focus-or-close)
  :config
  (setq imenu-list-focus-after-activation nil)
  ;; Must come after the package loads: imenu-list installs its own placement
  ;; rule at load time, which splits the frame root window and cannot coexist
  ;; with treemacs' side window. A rule set afterwards takes precedence.
  ;; display-buffer-in-side-window joins treemacs' column below it; drop
  ;; :actions to get a second full-height column instead.
  (set-popup-rule! "^\\*Ilist\\*$"
    :actions '(display-buffer-in-side-window)
    :side 'left :size 35 :height 0.45 :slot 1
    :quit nil :select nil :ttl nil)
  ;; imenu-list's idle refresh is skipped when point is at the same position
  ;; as in the previous buffer, so a freshly opened file keeps the old outline
  ;; until the cursor moves. Refresh on every buffer switch instead.
  (defun +outline-follow-buffer-h (frame)
    (with-current-buffer (window-buffer (frame-selected-window frame))
      (when (and imenu-list-minor-mode
                 (not (minibufferp))
                 (not (derived-mode-p 'imenu-list-major-mode)))
        (ignore-errors (imenu-list-update t)))))
  (add-hook 'window-buffer-change-functions #'+outline-follow-buffer-h))

;; *.md opens in plain markdown-mode, which already highlights code blocks in
;; their own language. poly-markdown (pulled in by :lang ess) claims *.md from
;; its autoloads, and claims it again whenever it loads, since quarto-mode and
;; poly-R require it.
(setq auto-mode-alist (rassq-delete-all 'poly-markdown-mode auto-mode-alist))
(after! poly-markdown
  (setq auto-mode-alist (rassq-delete-all 'poly-markdown-mode auto-mode-alist)))

;; Zen mode (SPC t z) blew the font up as the cursor entered code blocks.
;; polymode (pulled in by :lang ess; *.qmd and *.Rmd files use it) gives each
;; code-block language its own indirect buffer and carries the text's face
;; remappings over to it, but not the cookie text-scale uses to find its own
;; entry among them. Zen's text scaling, rerun in each new buffer, then stacked
;; another 1.44x on top instead of replacing it.
(after! polymode-core
  (add-to-list 'polymode-move-these-vars-from-old-buffer
               'text-scale-mode-remapping))

;; In .qmd files, markdown-mode paints a whole code block with
;; markdown-code-face while polymode paints the code with its own faint shade,
;; and a block keeps whichever ran last: the first block of a file came up grey
;; and the rest almost white. Have polymode paint markdown-code-face too.
(after! poly-markdown
  (oset poly-markdown-fenced-code-innermode adjust-face 'markdown-code-face))

;; C and C++ use the tree-sitter modes, with grammars from home.nix. Emacs 30's
;; cc-mode registers c-mode -> c-ts-mode remaps together with entries that keep
;; them off, and Doom's :lang cc deletes those entries, so the switch used to
;; happen only once cc-mode had loaded, grammar or not: later .c files and the
;; ```c blocks of .qmd files got c-ts-mode, and with no grammar, no highlighting.
;; Remapping from the start gives every C buffer the same mode.
(dolist (remap '((c-mode . c-ts-mode)
                 (c++-mode . c++-ts-mode)
                 (c-or-c++-mode . c-or-c++-ts-mode)))
  (add-to-list 'major-mode-remap-alist remap))

;; K&R at 4 columns plus indented case labels: Doom's cc-mode "doom" style.
(defun +c-ts-doom-indent-style ()
  `(((node-is "case") parent-bol c-ts-mode-indent-offset)
    ,@(alist-get 'k&r (c-ts-mode--indent-styles
                       (if (derived-mode-p 'c++-ts-mode) 'cpp 'c)))))
(setq c-ts-mode-indent-offset 4
      c-ts-mode-indent-style #'+c-ts-doom-indent-style)

;; Claude Code sessions live in vterm buffers, or in Claude's background daemon,
;; which a vterm buffer can show with `claude attach'. Once a minute, the
;; running ones are recorded, each with the buffer showing it, if one does, and
;; that buffer's workspaces. A session that stops while Emacs runs was ended on
;; purpose and leaves the record; one that an Emacs restart or a reboot killed
;; stays in it. SPC o C reopens the recorded sessions that aren't running or
;; aren't shown, in buffers of their old names. It follows a conversation that
;; went on in another session, as a busy one does when its terminal hangs up,
;; and it never starts a conversation twice. SPC o c starts a new session,
;; offering its name for the buffer's name too.
(defvar +claude-program "claude")
(defvar +claude-new-session-args
  '("--model" "claude-opus-5-5" "--effort" "max" "--remote-control")
  "Flags for a session started with `+claude/new-session'.")
(defvar +claude-dir "~/.claude"
  "Claude's state: transcripts in projects/, a file per running Claude in sessions/.")
;; next to Doom's own state; the profile dir is doom-data-dir unless Doom runs
;; under a profile, as nix-doom-emacs-unstraightened does
(defvar +claude-sessions-file
  (file-name-concat doom-profile-data-dir "claude-sessions.eld"))
(defvar +claude--seen nil "Ids of the sessions seen running in this Emacs.")
(defvar +claude--shown nil "Ids of the sessions seen in a vterm buffer in this Emacs.")
(defvar +claude--missing nil "Ids seen before that weren't running at the last check.")
(defvar +claude--reopened nil
  "What SPC o C reopened in this Emacs, as (ID . BUFFER-OR-TIME), so a second
press can't reopen it again: while its buffer lives, or for two minutes after a
respawn, before Claude lists it as running.")
(defvar +claude--timer nil)

;; --all adds the background sessions that aren't running: stopped or done
(defconst +claude--agents-command "exec \"$0\" agents --json --all 2>/dev/null")

(defun +claude--parse-agents (buffer)
  "The sessions listed in BUFFER, or `:failed' if it holds no listing."
  (with-current-buffer buffer
    (goto-char (point-min))
    (condition-case nil
        ;; a null pid must read as no process, not as the true-ish :null
        (json-parse-buffer :object-type 'plist :array-type 'list
                           :null-object nil :false-object nil)
      (error :failed))))

(defun +claude--agents ()
  "The Claude sessions, as `claude agents --json --all' lists them."
  (with-temp-buffer
    (let ((sessions (if (zerop (call-process "sh" nil t nil "-c"
                                             +claude--agents-command +claude-program))
                        (+claude--parse-agents (current-buffer))
                      :failed)))
      (when (eq sessions :failed)
        (user-error "Couldn't list the Claude sessions"))
      sessions)))

(defun +claude--agents-async (callback)
  "Call CALLBACK with what `+claude--agents' returns, without blocking.
A failed listing skips the call, so it can't pass for no sessions running."
  (let ((buffer (generate-new-buffer " *claude-agents*")))
    (make-process
     :name "claude-agents" :buffer buffer :noquery t :connection-type 'pipe
     :command (list "sh" "-c" +claude--agents-command +claude-program)
     :sentinel (lambda (process _event)
                 (unless (process-live-p process)
                   (unwind-protect
                       (let ((sessions (if (zerop (process-exit-status process))
                                           (+claude--parse-agents buffer)
                                         :failed)))
                         (unless (eq sessions :failed)
                           (funcall callback sessions)))
                     (kill-buffer buffer)))))))

(defun +claude--children (pid)
  "The processes that process PID started."
  (cl-loop for file in (file-expand-wildcards (format "/proc/%d/task/*/children" pid))
           nconc (mapcar #'string-to-number
                         (split-string (with-temp-buffer
                                         (ignore-errors (insert-file-contents-literally file))
                                         (buffer-string))))))

(defun +claude--args (pid)
  "The arguments of the Claude that process PID runs, if it runs one."
  (let ((argv (with-temp-buffer
                (ignore-errors
                  (insert-file-contents-literally (format "/proc/%d/cmdline" pid)))
                (split-string (buffer-string) "\0" t))))
    (cdr (cl-member-if (lambda (arg)
                         (member (file-name-nondirectory arg) '("claude" ".claude-wrapped")))
                       argv))))

(defun +claude--in-vterm-buffers ()
  "The processes running in vterm buffers, as (PID . BUFFER): what the shells
started, and what any of that but Claude started in turn, as `nix shell' does."
  (cl-loop for buffer in (buffer-list)
           for shell = (get-buffer-process buffer)
           when (and shell (eq (buffer-local-value 'major-mode buffer) 'vterm-mode))
           nconc (cl-loop for pid in (+claude--children (process-id shell))
                          collect (cons pid buffer)
                          unless (+claude--args pid)
                          nconc (mapcar (lambda (child) (cons child buffer))
                                        (+claude--children pid)))))

(defun +claude--flags (args)
  "The flags in Claude's ARGS, minus the ones a restore sets itself."
  (let (flags)
    (while args
      (pcase (pop args)
        ((or "-n" "--name" "--session-id") (pop args))
        ((or "-r" "--resume")           ; optional value: an id or search term
         (unless (string-prefix-p "-" (or (car args) "-")) (pop args)))
        ((or "-c" "--continue" "--fork-session"))
        (arg (push arg flags))))
    (nreverse flags)))

(defun +claude--registration (pid)
  "What the Claude in process PID says about itself in Claude's sessions dir."
  (ignore-errors
    (with-temp-buffer
      (insert-file-contents (expand-file-name (format "sessions/%d.json" pid) +claude-dir))
      (json-parse-buffer :object-type 'plist :null-object nil :false-object nil))))

(defun +claude--continued-in (session)
  "The session SESSION's conversation went on in, if its transcript says so.
A busy session whose terminal hangs up goes on in the background under a new
id, and Claude marks the old transcript with that id. A turn after the mark
means the old session was resumed after all, and the mark no longer holds."
  (when-let* ((session)
              (file (car (file-expand-wildcards
                          (expand-file-name (concat "projects/*/" session ".jsonl")
                                            +claude-dir))))
              (size (file-attribute-size (file-attributes file))))
    (with-temp-buffer
      ;; only a few bookkeeping entries follow the mark
      (ignore-errors (insert-file-contents file nil (max 0 (- size 65536)) size))
      (goto-char (point-max))
      (catch 'found
        (while (re-search-backward "^{" nil t)
          (let ((entry (ignore-errors
                         (json-parse-string (buffer-substring (point) (line-end-position))
                                            :object-type 'plist :null-object nil
                                            :false-object nil))))
            (pcase (plist-get entry :type)
              ("continued-in" (throw 'found (plist-get entry :continuedInSessionId)))
              ((or "user" "assistant") (throw 'found nil)))))))))

(defun +claude--now (session)
  "The session SESSION's conversation lives in now, following continued-in."
  (let ((hops 0) next)
    (while (and (< hops 8) (setq next (+claude--continued-in session)))
      (setq session next hops (1+ hops)))
    session))

(defun +claude--job (session sessions)
  "The background session in SESSIONS whose conversation is SESSION."
  (seq-find (lambda (s) (and (equal (plist-get s :kind) "background")
                             (equal (plist-get s :sessionId) session)))
            sessions))

(defun +claude--viewers (sessions processes)
  "The background SESSIONS that vterm PROCESSES show, as (ID . BUFFER): through
`claude attach ID', or as the Claude whose session left it for the background."
  (cl-loop for (pid . buffer) in processes
           for args = (+claude--args pid)
           for id = (if (equal (car args) "attach")
                        (let ((arg (cadr args)))
                          (if (and arg (string-match-p "\\`[0-9a-f]\\{8\\}\\'" arg))
                              arg
                            (plist-get (+claude--job arg sessions) :id)))
                      ;; a Claude listed with its pid runs its own session
                      (when-let* (((not (seq-find (lambda (s) (eql (plist-get s :pid) pid))
                                                  sessions)))
                                  (self (+claude--registration pid)))
                        (or (plist-get self :parkedJobId)
                            (when-let* ((session (plist-get self :sessionId))
                                        (now (+claude--now session))
                                        ((not (equal now session))))
                              (plist-get (+claude--job now sessions) :id)))))
           when id collect (cons id buffer)))

(defun +claude--workspaces-of (buffer)
  "The names of the workspaces BUFFER belongs to."
  (when (bound-and-true-p persp-mode)
    (cl-loop for workspace in (+workspace-list)
             when (persp-contain-buffer-p buffer workspace)
             collect (persp-name workspace))))

(defun +claude--in-vterms (sessions processes)
  "The SESSIONS running in vterm PROCESSES, in the form they are recorded in."
  (cl-loop for session in sessions
           for pid = (plist-get session :pid)
           for buffer = (and pid (equal (plist-get session :kind) "interactive")
                             (alist-get pid processes))
           when buffer
           collect (list :session (plist-get session :sessionId)
                         :name (plist-get session :name)
                         :buffer (buffer-name buffer)
                         :workspaces (+claude--workspaces-of buffer)
                         :dir (plist-get session :cwd)
                         :flags (+claude--flags (+claude--args pid)))))

(defun +claude--in-background (sessions viewers)
  "The background SESSIONS running or shown, in the form they are recorded in,
with the vterm buffer that VIEWERS says shows one."
  (cl-loop for session in sessions
           for id = (plist-get session :id)
           for viewer = (cdr (assoc id viewers))
           when (and (equal (plist-get session :kind) "background")
                     (or (plist-get session :pid)
                         ;; Without a process, it counts if Claude takes it for
                         ;; running, or if it's done but shown; not if stopped
                         ;; on purpose, or if its conversation went on in
                         ;; another session, as a hangup's leftover.
                         (and (not (equal (plist-get session :state) "stopped"))
                              (or viewer (not (equal (plist-get session :state) "done")))
                              (not (+claude--continued-in (plist-get session :sessionId))))))
           collect (append (list :session (plist-get session :sessionId)
                                 :name (plist-get session :name)
                                 :dir (plist-get session :cwd)
                                 :background id)
                           (when viewer
                             (list :buffer (buffer-name viewer)
                                   :workspaces (+claude--workspaces-of viewer))))))

(defun +claude--into-workspaces (buffer names)
  "Put BUFFER into the workspaces called NAMES, creating the missing ones, or
into the current one when NAMES is empty. Take it out of the current one unless
that is one of them, since Doom adds a buffer there once it shows up. Return
BUFFER."
  (when (bound-and-true-p persp-mode)
    (let ((names (remove persp-nil-name (or names (list (+workspace-current-name))))))
      (dolist (name names)
        (persp-add-buffer buffer (or (+workspace-get name t) (+workspace-new name)) nil nil))
      (unless (member (+workspace-current-name) names)
        ;; Doom kills a buffer removed from its last workspace; this isn't one.
        (let ((persp-autokill-buffer-on-remove nil))
          (persp-remove-buffer buffer (+workspace-current))))))
  buffer)

(defun +claude--read-record ()
  (ignore-errors
    (with-temp-buffer
      (insert-file-contents +claude-sessions-file)
      (read (current-buffer)))))

(defun +claude--write-record (record)
  (make-directory (file-name-directory +claude-sessions-file) t) ; new hosts lack it
  (with-temp-file +claude-sessions-file
    (let ((print-length nil) (print-level nil))
      (prin1 record (current-buffer)))))

(defun +claude--same-p (entry now running)
  "Whether the recorded ENTRY, whose conversation lives in session NOW, is the
RUNNING one's: the same session or background session, or an older session the
conversation went on from."
  (or (member (plist-get running :session) (list now (plist-get entry :session)))
      (and (plist-get entry :background)
           (equal (plist-get entry :background) (plist-get running :background)))))

(defun +claude--shown-p (entry)
  "Whether ENTRY's session was seen in a vterm buffer in this Emacs."
  (or (member (plist-get entry :session) +claude--shown)
      (and (plist-get entry :background)
           (member (plist-get entry :background) +claude--shown))))

(defun +claude--with-buffer (running old)
  "The RUNNING session, given the buffer of its OLD record when it has none and
had none in this Emacs: one that an Emacs restart closed, to be reopened. OLD
holds the record as (NOW . ENTRY), NOW being the session ENTRY lives in now."
  (if-let* (((not (plist-get running :buffer)))
            ((not (+claude--shown-p running)))
            (from (cl-loop for (now . entry) in old
                           thereis (and (plist-get entry :buffer)
                                        (not (+claude--shown-p entry))
                                        (+claude--same-p entry now running)
                                        entry))))
      (append running (list :buffer (plist-get from :buffer)
                            :workspaces (plist-get from :workspaces)))
    running))

(defun +claude--record (running)
  "Fold the RUNNING sessions into the record. A session seen running earlier
leaves it once it has been missing at two checks in a row, so one dying with
Emacs at shutdown can't cost the others their place. An older form of a running
session leaves it at once, its buffer passing on to the running one if that has
none yet."
  (let ((old (mapcar (lambda (entry) (cons (+claude--now (plist-get entry :session)) entry))
                     (+claude--read-record)))
        kept missing)
    (setq +claude--shown (seq-union (cl-loop for r in running
                                             when (plist-get r :buffer)
                                             nconc (delq nil (list (plist-get r :session)
                                                                   (plist-get r :background))))
                                    +claude--shown)
          running (mapcar (lambda (r) (+claude--with-buffer r old)) running))
    (pcase-dolist (`(,now . ,entry) old)
      (let ((id (plist-get entry :session)))
        (cond ((seq-some (lambda (r) (+claude--same-p entry now r)) running)) ; recorded afresh
              ((not (member id +claude--seen)) (push entry kept)) ; not reopened yet
              ((member id +claude--missing))  ; missing twice: ended
              (t (push id missing) (push entry kept)))))
    (setq +claude--seen (seq-union (mapcar (lambda (r) (plist-get r :session)) running)
                                   +claude--seen)
          +claude--missing missing)
    (+claude--write-record (append running (nreverse kept)))))

(defun +claude--check ()
  (when (executable-find +claude-program)
    (+claude--agents-async
     (lambda (sessions)
       (let ((processes (+claude--in-vterm-buffers)))
         (+claude--record
          (append (+claude--in-vterms sessions processes)
                  (+claude--in-background sessions
                                          (+claude--viewers sessions processes)))))))))

(defun +claude--shell-command (args)
  "The command line running Claude with ARGS, quoted for the vterm shell."
  (mapconcat (lambda (arg)
               (cond ((string-match-p "\\`[[:alnum:]_./:=@%+,-]+\\'" arg) arg)
                     ((string-suffix-p "fish" vterm-shell)
                      (concat "'" (replace-regexp-in-string "[\\']" "\\\\\\&" arg) "'"))
                     (t (shell-quote-argument arg))))
             (cons +claude-program args) " "))

(defun +claude--launch (dir name &rest commands)
  "Type Claude COMMANDS, each a list of arguments, into the shell of a new vterm
buffer NAME started in DIR, to run one after another."
  (require 'vterm)                      ; a fresh Emacs hasn't loaded it yet
  (let ((default-directory (file-name-as-directory
                            (expand-file-name (if (and dir (file-directory-p dir)) dir "~")))))
    (with-current-buffer (save-window-excursion (vterm (generate-new-buffer-name name)))
      (vterm-send-string (mapconcat #'+claude--shell-command commands "; "))
      (vterm-send-return)
      (current-buffer))))

(defun +claude--label (entry)
  (format "%s  %s  [%s]" (plist-get entry :name)
          (abbreviate-file-name (plist-get entry :dir))
          (if (plist-get entry :buffer)
              (string-join (plist-get entry :workspaces) ", ")
            "background")))

(defun +claude--plan (entry sessions shown)
  "What reopening the recorded ENTRY takes, given the listed SESSIONS and the
ids of those SHOWN in vterm buffers: nil, (attach ID REVIVE), (respawn ID) or
(resume SESSION)."
  (let* ((recorded (plist-get entry :session))
         (now (+claude--now recorded))
         (job (or (+claude--job now sessions)
                  (and (equal now recorded)
                       (plist-get entry :background)
                       (seq-find (lambda (s)
                                   (and (equal (plist-get s :kind) "background")
                                        (equal (plist-get s :id) (plist-get entry :background))))
                                 sessions))))
         (id (plist-get job :id)))
    (cond
     ((or (member now shown) (and id (member id shown))) nil)
     ((null job)
      (cond ((seq-find (lambda (s) (and (plist-get s :pid)
                                        (equal (plist-get s :sessionId) now)))
                       sessions)
             nil)                       ; running in a terminal outside Emacs
            ((plist-get entry :buffer) (list 'resume now))))
     ((equal (plist-get job :state) "stopped") nil) ; stopped on purpose
     ;; Reopen its buffer as a view of it, restarting it first if it isn't
     ;; running, or else just restart it, in place either way: `--bg --resume'
     ;; starts a copy of a session the daemon believes running.
     ((plist-get entry :buffer) (list 'attach id (not (plist-get job :pid))))
     ((not (plist-get job :pid)) (list 'respawn id)))))

(defun +claude--reopening-p (reopened)
  (let ((where (cdr reopened)))
    (if (bufferp where)
        (buffer-live-p where)
      (< (float-time (time-since where)) 120))))

(defun +claude/restore-sessions (&optional pick)
  "Reopen the recorded Claude sessions that aren't running or aren't shown.
One that lived in a vterm resumes there. One in the background, sent there or
moved there by a hangup, reopens its buffer as `claude attach', after `claude
respawn' if it isn't running; one without a buffer is just respawned. Claude's
continued-in marks lead to where a conversation went on, so its latest form
reopens, and no conversation starts twice. Buffers keep their old names, or
take the session's in place of a default `*vterm*' one, and go back into their
workspaces. With a prefix argument, pick which to reopen; the rest are
forgotten."
  (interactive "P")
  (let* ((sessions (+claude--agents))
         (processes (+claude--in-vterm-buffers))
         (shown (append (mapcar #'car (+claude--viewers sessions processes))
                        (mapcar (lambda (s) (plist-get s :session))
                                (+claude--in-vterms sessions processes))
                        (mapcar #'car (setq +claude--reopened
                                            (seq-filter #'+claude--reopening-p
                                                        +claude--reopened)))))
         (record (+claude--read-record))
         ;; Of two entries for one conversation, one with a buffer wins.
         (todo (cl-loop with targets = nil
                        for entry in (seq-sort-by (lambda (e) (if (plist-get e :buffer) 0 1))
                                                  #'< record)
                        for plan = (+claude--plan entry sessions shown)
                        when (and plan (not (member (cadr plan) targets)))
                        do (push (cadr plan) targets)
                        and collect (cons entry plan))))
    (when pick
      (let ((chosen (completing-read-multiple
                     "Reopen: " (mapcar (lambda (x) (+claude--label (car x))) todo) nil t)))
        (+claude--write-record
         (seq-remove (lambda (s) (and (assq s todo)
                                      (not (member (+claude--label s) chosen))))
                     record))
        (setq todo (seq-filter (lambda (x) (member (+claude--label (car x)) chosen)) todo))))
    (pcase-dolist (`(,entry . ,plan) todo)
      (let* ((name (plist-get entry :name))
             (old (plist-get entry :buffer))
             (buffer (if (or (null old)
                             (and name (string-match-p "\\`\\*vterm\\*\\(<[0-9]+>\\)?\\'" old)))
                         (concat "*vterm*" name)
                       old))
             (dir (plist-get entry :dir))
             (flags (plist-get entry :flags)))
        (push (cons (cadr plan)
                    (pcase plan
                      (`(respawn ,id)     ; returns at once
                       (call-process +claude-program nil 0 nil "respawn" id)
                       (current-time))
                      (`(attach ,id ,revive)
                       (+claude--into-workspaces
                        (apply #'+claude--launch dir buffer
                               (append (when revive (list (list "respawn" id)))
                                       (list (list "attach" id))))
                        (plist-get entry :workspaces)))
                      (`(resume ,session)
                       (+claude--into-workspaces
                        (+claude--launch
                         dir buffer
                         (append flags
                                 ;; all of them within reach of claude.ai and the phone
                                 (unless (member "--remote-control" flags)
                                   '("--remote-control"))
                                 (list "--resume" session)
                                 (when name (list "--name" name))))
                        (plist-get entry :workspaces)))))
              +claude--reopened)))
    (message "Reopened %d Claude session%s" (length todo) (if (= (length todo) 1) "" "s"))))

(defun +claude/new-session (dir name bufname)
  "Start a Claude session called NAME in DIR, in a vterm buffer called BUFNAME.
Interactively, BUFNAME starts out as *vterm*NAME, to keep or edit."
  (interactive
   (let* ((dir (read-directory-name "Directory: " (or (doom-project-root) default-directory)))
          (name (read-string "Session name: "
                             (file-name-nondirectory (directory-file-name dir)))))
     (list dir name (read-string "Buffer name: " (concat "*vterm*" name)))))
  (let ((buffer (+claude--launch dir bufname
                                 (append +claude-new-session-args (list "--name" name)))))
    (+claude--into-workspaces buffer nil)
    (pop-to-buffer-same-window buffer))
  (run-with-timer 15 nil #'+claude--check))

(unless +claude--timer
  (setq +claude--timer (run-with-timer 60 60 #'+claude--check)))

(map! :leader
      :desc "New Claude session" "o c" #'+claude/new-session
      :desc "Reopen Claude sessions" "o C" #'+claude/restore-sessions)
