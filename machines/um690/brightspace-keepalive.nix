# brightspace-keepalive.nix — one API call every 15 minutes, so the Brightspace
# session in ~/.local/state/brightspace does not idle out.
#
# Commonwealth logs in through single sign-on (Cirrus, then Entra), so there is
# no password a script can use and `brightspace.py session` instead takes the
# session Firefox is already holding. D2L then expires it after a stretch with no
# activity — measured dead after about fifty minutes idle on 2026-09-26, which
# fits the vendor default of thirty, and not the 180 the login page advertises.
# An API call counts as activity for that session, and it is the *browser's*
# session, so this keeps Firefox logged in too.
#
# A ping that finds the session dead re-reads Firefox's session store and
# retries, so the pair repairs itself whenever the browser has a live session.
# That is why a failure here is a journal line and not an incident: the next run
# tries again. `journalctl -u brightspace-keepalive -n 20` says which it was.
#
# What it costs: an instructor session that does not idle out, which is also a
# browser that stays logged in to Brightspace. Worth knowing rather than worth
# avoiding — the session reaches every grade in every course, so the thing
# protecting it is the locked screen and not the idle timeout.
{ config, lib, pkgs, ... }:

let
  edu = "/home/artem/edu";
  state = "/home/artem/.local/state/brightspace";
  # brightspace.py's shebang is `nix-shell -i python3 -p "python3.withPackages
  # (ps: [ps.lz4])"`, and course-status.nix documents what that costs a unit: a
  # PATH with nix on it plus a NIX_PATH to resolve <nixpkgs> through. Naming the
  # interpreter here skips the shebang and both problems — the closure is one
  # python, already built, and nothing is resolved at runtime.
  #
  # lz4 is not decoration: the two session cookies live in Firefox's session
  # store, `sessionstore-backups/recovery.jsonlz4`, because Brightspace sets them
  # with no expiry and Firefox keeps those out of cookies.sqlite. mozlz4 is that
  # file's container. Everything else the script needs is stdlib.
  python = pkgs.python3.withPackages (ps: [ ps.lz4 ]);
in
{
  systemd.services.brightspace-keepalive = {
    description = "Keep the Brightspace session from idling out";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    # Nothing to do until a session exists, so skip rather than fail: without this
    # the timer would fail every 15 minutes from first boot until the first
    # `brightspace.py session`, which is a lot of journal for "not set up yet".
    #
    # It is a [Unit] directive and not a [Service] one. In serviceConfig it lands
    # in the wrong section, where systemd ignores it — a condition that silently
    # never holds, which is worse than not having one.
    unitConfig.ConditionPathIsDirectory = state;

    serviceConfig = {
      Type = "oneshot";

      # A system unit running as artem, for the reason course-status.nix gives:
      # nothing here needs a user manager, and staying out of one means this does
      # not quietly depend on `users.users.artem.linger` being set by a different
      # module in order to come up at boot. It runs as artem because both things
      # it touches are his — the session it keeps alive, and the Firefox profile
      # it re-reads when that session has died.
      User = "artem";
      Environment = [ "HOME=/home/artem" ];

      # --quiet says nothing when it works, so the journal holds failures only.
      ExecStart = "${python}/bin/python3 ${edu}/scripts/brightspace.py ping --quiet";

      # The checkout is live working data and the script is edited by hand, so the
      # unit is given no way to write to it. The session directory stays writable:
      # repairing an expired session rewrites it, which is the point.
      ReadOnlyPaths = [ edu ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.timers.brightspace-keepalive = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Comfortably inside the idle window, with room for a missed run.
      OnBootSec = "2min";
      OnUnitActiveSec = "15min";
      AccuracySec = "1min";
      # Catching up a missed keep-alive is pointless: either the session is still
      # alive, in which case the next run handles it, or it expired while the
      # machine was off and no amount of pinging brings it back.
      Persistent = false;
    };
  };
}
