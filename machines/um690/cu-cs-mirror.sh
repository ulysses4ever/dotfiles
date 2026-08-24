# Mirror all cu-cs-courses sites to a local directory served by Apache.
# Runs as a systemd timer on um690; tolerates GitHub being unreachable.
#
# shebang and set -euo pipefail are added by pkgs.writeShellApplication.

REPOS_DIR=/home/artem/tmp/course-repos
WWW_DIR=/home/artem/cu-cs-courses/www

GH_BASE=https://github.com/cu-cs-courses

COURSE_REPOS=(
  cmsc-100-f2026
  cmsc-115-f2026
  cmsc-120-f2026
  cmsc-230-f2026
  cmsc-240-f2026
)

# Tries to pull / clone from GitHub.
# Returns:
#   0 — something changed or www not yet populated: build needed
#   1 — already up to date and www exists: skip build
#   2 — no local checkout and GitHub unreachable: skip entirely
sync_repo() {
  local repo=$1
  local dir="$REPOS_DIR/$repo"

  if [[ ! -d "$dir/.git" ]]; then
    git clone --quiet "$GH_BASE/$repo.git" "$dir" || return 2
    return 0
  fi

  if git -C "$dir" fetch --quiet origin main 2>/dev/null; then
    local behind
    behind=$(git -C "$dir" rev-list HEAD..origin/main --count)
    if [[ "$behind" -gt 0 ]]; then
      git -C "$dir" merge --ff-only origin/main || true  # local commits ahead: build anyway
    elif [[ -d "$WWW_DIR/$repo" ]]; then
      return 1  # up to date and already deployed
    fi
  else
    echo "GitHub unreachable, building from local checkout"
  fi
  return 0
}

# Landing page — plain HTML, no Quarto build.
echo "=== cu-cs-courses.github.io ==="
rc=0; sync_repo cu-cs-courses.github.io || rc=$?
if [[ $rc -eq 2 ]]; then
  echo "no local checkout and GitHub unreachable, skipping"
elif [[ $rc -eq 1 ]]; then
  echo "landing page up to date"
else
  rsync -a --delete \
    --exclude='/cmsc-*/' \
    --exclude='/.git/' \
    --exclude='/README.md' \
    "$REPOS_DIR/cu-cs-courses.github.io/" "$WWW_DIR/"
  echo "landing page updated"
fi

# Course repos — Quarto build needed.
for repo in "${COURSE_REPOS[@]}"; do
  echo "=== $repo ==="
  rc=0; sync_repo "$repo" || rc=$?
  if [[ $rc -eq 2 ]]; then
    echo "no local checkout and GitHub unreachable, skipping"
  elif [[ $rc -eq 1 ]]; then
    echo "up to date"
  else
    # NIX_PATH as CI sets it: shell.nix imports the pin directly, but nix-shell
    # itself resolves <nixpkgs> for bashInteractive and there are no channels here.
    (cd "$REPOS_DIR/$repo" \
      && NIX_PATH="nixpkgs=$REPOS_DIR/$repo/config/nixpkgs.nix" nix-shell --run 'make render')
    rsync -a --delete "$REPOS_DIR/$repo/_site/" "$WWW_DIR/$repo/"
    echo "updated"
  fi
done
