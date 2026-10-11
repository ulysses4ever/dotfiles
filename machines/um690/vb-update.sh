# Daily update of the Visa Bulletin Tracker (github.com/ulysses4ever/vb):
# import any new bulletin and USCIS's chart for it, then push, which redeploys
# https://ulysses4ever.github.io/vb/. Runs as a systemd timer on um690.
#
# shebang and set -euo pipefail are added by pkgs.writeShellApplication.

DIR="${STATE_DIRECTORY:-/var/lib/vb-update}/vb"

# The deploy key can write to this one repository and nothing else. Artem's own
# key sits behind gpg-agent, whose cached passphrase is long gone by the 3rd.
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/vb-deploy -o IdentitiesOnly=yes -o IdentityAgent=none"

# A clone of its own rather than the working copy in ~/Dev, so a run never trips
# over, or commits, work in progress there. Reset to origin every time, which
# also clears whatever a failed run left behind.
if [[ ! -d "$DIR/.git" ]]; then
  git clone --quiet git@github.com:ulysses4ever/vb.git "$DIR"
fi
cd "$DIR"
git fetch --quiet origin main
git reset --quiet --hard origin/main

# 0: data/ has this month's bulletin. 3: the dataset doesn't have it yet, but
# what it does have was imported, so publish that before failing the unit.
rc=0
python3 -u tools/update.py || rc=$?
if [[ $rc -ne 0 && $rc -ne 3 ]]; then
  exit "$rc"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  added=$(git -C data/bulletins ls-files --others --exclude-standard)
  added=${added//.json/}
  added=${added//$'\n'/ }
  what=${added:+add $added}
  git add data site
  git commit --quiet -m "data: ${what:-USCIS chart} (vb-update on um690)"
  git push --quiet origin HEAD:main
  echo "pushed $(git rev-parse --short HEAD)"
fi
exit "$rc"
