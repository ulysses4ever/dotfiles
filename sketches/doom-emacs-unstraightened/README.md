# Doom Emacs via nix-doom-emacs-unstraightened (parked)

Issue: https://github.com/ulysses4ever/dotfiles/issues/3

Replace the hand-installed Doom (`~/.config/emacs` + straight.el + `doom sync`)
with [nix-doom-emacs-unstraightened], which builds Doom and every package with
Nix, pinned by `flake.lock`.

[nix-doom-emacs-unstraightened]: https://github.com/marienz/nix-doom-emacs-unstraightened

## Status

Parked 2026-10-01. **Built and smoke-tested on um690, never switched to, never
committed.**

- Patch base: `a5c7ca5` (packages: a full python3 with lz4 and pyyaml).
- Full um690 system toplevel built. All four hosts evaluated.
- `migrate-state.sh` tested only as far as its safety check.

## Files

| File | What |
|---|---|
| `doom-emacs-unstraightened.patch` | The whole change: flake, home-manager, doom.d |
| `migrate-state.sh` | One-shot copy of Doom state to the new locations, run at cutover |

## Resuming

```
cd ~/dotfiles
git apply sketches/doom-emacs-unstraightened/doom-emacs-unstraightened.patch
nix build --no-link .#nixosConfigurations.um690.config.system.build.toplevel
```

If `flake.lock` has moved on since the base commit, its hunk will not apply.
Apply the rest with `git apply --exclude=flake.lock ...` and run
`nix flake lock`: it only adds the new input and leaves existing pins alone.

The first build is slow. It fetches ~220 pinned sources and native-compiles
~330 derivations. No binary cache covers it, because Unstraightened's cachix
is built against nixpkgs-unstable and this flake is on 26.05.

## What the patch changes

- **flake.nix**: new input `nix-doom-emacs-unstraightened` with
  `inputs.nixpkgs.follows = ""`. The home-manager module builds against
  home-manager's own pkgs, so a second nixpkgs would never be read. Its
  `homeModule` is imported into `home-manager.users.artem`.
- **home.nix**: `programs.emacs` and the `~/.config/doom` symlink are replaced
  by `programs.doom-emacs`. `programs.emacs` has to go: both modules put an
  `emacs` into the profile. The module also sets `services.emacs.package`, so
  the daemon follows automatically.
- **doom.d/packages.el**: `pyret` gets a `:pin`.
- **doom.d/init.el**: `doom-dashboard` is now `dashboard`, and `rgb` is dropped.
- **doom.d/config.el**: `emojify-download-emojis-p` is set to `t`.

## Findings and decisions

**pyret needs a pin.** Unstraightened refuses to build a `:recipe` package that
emacs-overlay doesn't provide unless it is pinned. pyret isn't on MELPA. The
pin is `99c83468`, the commit straight.el had checked out and the one known to
work. The next upstream commit to touch `pyret.el` (`6e62dcda52`) only adds a
`lexical-binding: t` cookie. Worth taking, but it changes scoping for the whole
file, so it stays out of an infrastructure change. copilot, copilot-chat,
mermaid-mode and ob-mermaid are on MELPA and need no pin.

**`experimentalFetchTree = true`** fetches pinned packages as GitHub tarballs.
The default fetchGit does a full-history clone, and pyret's mode lives in the
~650M pyret-lang monorepo. It also sidesteps the "Cannot find Git revision"
fetchGit failures upstream reports on Nix newer than 2.18; this machine has
2.35.

**Doom moved.** Unstraightened pins Doom from September 2026, after Doom split
into `doomemacs/core` and `doomemacs/modules`. The local install is from
September 2025. Of the 70 modules in init.el, two needed changes:

- `:ui doom-dashboard` was replaced by `:ui dashboard` in June 2026.
- `:tools rgb` was removed in July 2024. It was already missing from the old
  install, so that line had been a silent no-op for over a year.
- `IS-MAC` in `(:if IS-MAC macos)` still works. It is deprecated, with removal
  slated for Doom v3.

**vterm and pdf-tools** were added by hand through `programs.emacs.extraPackages`.
Doom's `:term vterm` and `:tools pdf` modules pull them now, and Nix builds
their native halves: `vterm-module.so` and `epdfinfo`.

### Two regressions the migration caused, both fixed in the patch

**The emojify prompt hangs the daemon.** The `:ui emoji +github` module turns on
`global-emojify-mode` with the first buffer. emojify then needs an image set.
Its default `emojify-download-emojis-p` is `'ask`, so it asks with
`yes-or-no-p`. Unstraightened's data dir starts empty, so the question fires on
the first file visit. A daemon with no frame has no keyboard to answer it, and
the whole daemon wedges: it stops servicing every emacsclient request.

The old install never asked because the images were already in
`~/.config/emacs/.local/cache/emojis`. Setting the variable to `t` downloads
without asking, and a failed download errors instead of hanging.
`migrate-state.sh` also copies the existing images, so um690 needs no download.

How it was found: every prompting function was rebound to signal an error
carrying its arguments, then the file was opened. The error came back naming
the exact prompt.

**copilot-chat gets shadowed.** copilot.el 0.5.0 ships its own
`copilot-chat.el`, and so does the separate `copilot-chat` package from chep.
Both `(provide 'copilot-chat)`, so only the first on `load-path` ever loads.
Under straight.el chep's came first. That's the one the `SPC l` bindings in
config.el use: `copilot-chat-add-current-buffer` lives in chep's
`copilot-chat-command.el`. Under Unstraightened copilot's came first and broke
them.

The fix has to be in Nix. Unstraightened ignores a recipe's `:files` for
packages emacs-overlay already provides, so `packages.el` cannot express it.
home.nix overrides copilot's melpaBuild `files` to
`(:defaults "dist" (:exclude "copilot-chat.el"))`. After the fix all three
bound commands are `commandp`.

## Smoke test that passed

The build was started as a daemon under its own socket name, with
`XDG_{CACHE,DATA,STATE}_HOME` pointed at a scratch tree. That kept it away from
the real daemon and real state.

| Check | Result |
|---|---|
| Doom init | 72 modules, ~2.6s, native-comp on |
| `.arr` visit | `pyret-mode`, keywords highlighted, `+pyret-run` defined |
| localleader `r` in pyret-mode | `+pyret-run` |
| vterm | module loads |
| pdf-tools | `epdfinfo` built and executable |
| copilot | Nix `copilot-language-server` 1.495.0 starts; no `copilot-install-server` needed |
| `pyret`, `rg` | on PATH inside Emacs |

The daemon logs one harmless warning: `setq!` in config.el is an obsolete alias
for `setopt`.

## Cutover

Order matters. The old Emacs must stop so its state is final. The new one must
not start before the copy lands, or it writes empty history over it on exit.

```
systemctl --user stop emacs        # closes every frame: save buffers first
~/dotfiles/sketches/doom-emacs-unstraightened/migrate-state.sh
sudo nixos-rebuild switch --flake ~/dotfiles#um690
systemctl --user start emacs
```

The state map, read out of the built Emacs rather than guessed. Old paths are
under `~/.config/emacs/.local/`.

| Old | New |
|---|---|
| `cache/{recentf,savehist,saveplace,lsp-session,treemacs-persist,org-roam.db}` | `~/.cache/doom/nix/` (same names) |
| `cache/projectile.projects` | `~/.cache/doom/nix/projectile/projects.eld` |
| `cache/undo-fu-session/`, `cache/emojis/` | `~/.cache/doom/nix/` (same names) |
| `etc/{bookmarks,org-clock-save.el}`, `etc/workspaces/` | `~/.local/share/doom/nix/` |
| `etc/forge/forge-database.sqlite` | `~/.local/share/doom/nix/forge/` |
| `etc/transient/history` | `~/.local/share/doom/nix/transient/` |

Nothing to carry for the aspell personal dictionary: aspell was pointed at
`etc/ispell/.pws`, which was never created. The new location is
`~/.local/share/doom/ispell/.pws`. Note it is outside the `nix` profile dir. The
old `cache/eshell` was empty.

Keep `~/.config/emacs` as a fallback until satisfied, then delete it. It frees
1.6G on `/home`.

## Costs and consequences

- **Disk**: 290M of new store paths on `/` (299 paths). The full closure is 2.0
  GiB, but most of it, Emacs and GTK, is already there.
- **Workflow**: doom.d is baked into the store. A config edit now takes a
  rebuild plus an Emacs restart. `doom sync` and `doom/reload` no longer apply.
- **Other hosts**: `home.nix` is shared, so each laptop builds Doom on its next
  rebuild and meets an empty data dir. The emojify fix covers the hang there.
  `migrate-state.sh` has only `/home/artem` paths, so it works on any of them.
