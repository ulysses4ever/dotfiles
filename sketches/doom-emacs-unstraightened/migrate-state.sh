#!/usr/bin/env bash
# One-shot: carry Doom state from the straight.el install (~/.config/emacs)
# over to where nix-doom-emacs-unstraightened keeps it (profile "nix", under
# the XDG dirs). Run once at cutover, AFTER stopping the old daemon and BEFORE
# the new Emacs first starts -- otherwise the copy is stale, or the new Emacs
# overwrites it with empty history on exit.
#
# Every destination below was read out of the built Emacs itself
# (recentf-save-file, persp-save-dir, ...), not guessed. Copies, never moves:
# ~/.config/emacs stays intact as the fallback until you delete it.
set -euo pipefail

OLD=/home/artem/.config/emacs/.local
C=/home/artem/.cache/doom/nix
D=/home/artem/.local/share/doom/nix

if pgrep -x -f '.*emacs.*(--fg-daemon|--daemon).*' >/dev/null || pgrep -x emacs >/dev/null; then
  echo "An Emacs is still running. Stop it first:  systemctl --user stop emacs" >&2
  exit 1
fi

# old path (relative to $OLD)          new path
MAP=(
  "cache/recentf                       $C/recentf"
  "cache/savehist                      $C/savehist"
  "cache/saveplace                     $C/saveplace"
  "cache/projectile.projects           $C/projectile/projects.eld"
  "cache/undo-fu-session               $C/undo-fu-session"
  "cache/org-roam.db                   $C/org-roam.db"
  "cache/lsp-session                   $C/lsp-session"
  "cache/treemacs-persist              $C/treemacs-persist"
  "cache/emojis                        $C/emojis"
  "etc/bookmarks                       $D/bookmarks"
  "etc/workspaces                      $D/workspaces"
  "etc/forge/forge-database.sqlite     $D/forge/forge-database.sqlite"
  "etc/transient/history               $D/transient/history"
  "etc/org-clock-save.el               $D/org-clock-save.el"
)

for line in "${MAP[@]}"; do
  read -r src dst <<<"$line"
  if [ ! -e "$OLD/$src" ]; then
    printf 'skip  %-34s (not present in old install)\n' "$src"
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  # Something already there means the new Emacs ran before this script did.
  # Keep it aside rather than lose it.
  if [ -e "$dst" ]; then
    mv "$dst" "$dst.pre-migration"
    printf 'kept  %s.pre-migration\n' "$dst"
  fi
  # Directories: copy contents into dst (trailing /.), not dst/<name>.
  if [ -d "$OLD/$src" ]; then
    mkdir -p "$dst" && cp -a "$OLD/$src/." "$dst/"
  else
    cp -a "$OLD/$src" "$dst"
  fi
  printf 'copy  %-34s -> %s\n' "$src" "${dst/#\/home\/artem/\~}"
done
