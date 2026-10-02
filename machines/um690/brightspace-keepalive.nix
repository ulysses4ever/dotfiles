# brightspace-keepalive.nix — one API call per session every 15 minutes, so
# that no Brightspace session in ~/.config/brightspace/keepalive.ini idles out:
# Artem's, and Julia's.
#
# Commonwealth logs in through single sign-on (Cirrus, then Entra), so there is
# no password a script can use and `brightspace.py session` instead takes the
# session Firefox is already holding. D2L then expires it after a stretch with no
# activity — measured dead after about fifty minutes idle on 2026-09-26, which
# fits the vendor default of thirty, and not the 180 the login page advertises.
# An API call counts as activity for that session, and it is the *browser's*
# session, so this keeps Firefox logged in too.
#
# `brightspace.py keepalive` pings every session in that file. Artem's is a
# state directory, and a ping that finds it dead re-reads Firefox's session
# store and retries, so it repairs itself whenever the browser has a live
# session. Julia's is her two cookies, pasted in by hand: nothing here can
# repair those, so once they die every run says `julia  dead` until fresh ones
# replace them. Either way a failure is a journal line and not an incident:
# `journalctl -u brightspace-keepalive -n 20` says which session and why.
#
# The tool is public now, cu-cs-courses/brightspace-cli, cloned at
# ~/edu/brightspace-cli. Its systemd/ directory has user units that do this for
# one person on any machine; this one system unit does it for both of us, here.
#
# What it costs: sessions that do not idle out, which are also browsers that
# stay logged in to Brightspace. Each reaches every grade its owner can, so the
# thing protecting them is this machine's locked screen and the keepalive
# file's mode, not the idle timeout.
{ config, lib, pkgs, ... }:

let
  edu = "/home/artem/edu";
  # The list of sessions. Not declared here, and never can be: it holds
  # Julia's cookies, and anything a module writes lands in the world-readable
  # Nix store. It is a hand-edited file, mode 0600, which the tool refuses to
  # read if anyone else can.
  keepalive = "/home/artem/.config/brightspace/keepalive.ini";
  # brightspace.py's shebang is `/usr/bin/env python3`, and a unit's PATH has
  # no python on it. Naming the interpreter here also pins the one thing the
  # script needs beyond the standard library.
  #
  # lz4 is not decoration: Artem's two session cookies live in Firefox's session
  # store, `sessionstore-backups/recovery.jsonlz4`, because Brightspace sets them
  # with no expiry and Firefox keeps those out of cookies.sqlite. mozlz4 is that
  # file's container.
  python = pkgs.python3.withPackages (ps: [ ps.lz4 ]);
in
{
  systemd.services.brightspace-keepalive = {
    description = "Keep the Brightspace sessions from idling out";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    # Nothing to do until the list exists, so skip rather than fail: without
    # this the timer would fail every 15 minutes on a machine where nobody has
    # written one, which is a lot of journal for "not set up yet".
    #
    # It is a [Unit] directive and not a [Service] one. In serviceConfig it lands
    # in the wrong section, where systemd ignores it — a condition that silently
    # never holds, which is worse than not having one.
    unitConfig.ConditionPathExists = keepalive;

    serviceConfig = {
      Type = "oneshot";

      # A system unit running as artem, for the reason course-status.nix gives:
      # nothing here needs a user manager, and staying out of one means this does
      # not quietly depend on `users.users.artem.linger` being set by a different
      # module in order to come up at boot. It runs as artem because what it
      # touches is his: the keepalive file, his session, and the Firefox profile
      # it re-reads when that session has died.
      User = "artem";
      Environment = [ "HOME=/home/artem" ];

      # --quiet says nothing for a session that is alive, so the journal holds
      # failures only, one line per session, by its name in the file.
      ExecStart = "${python}/bin/python3 ${edu}/brightspace-cli/brightspace.py keepalive --quiet";

      # The checkouts are live working data and the script is edited by hand, so
      # the unit is given no way to write to them. The session directory stays
      # writable: repairing an expired session rewrites it, which is the point.
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
      # Catching up a missed keep-alive is pointless: either the sessions are
      # still alive, in which case the next run handles them, or they expired
      # while the machine was off and no amount of pinging brings them back.
      Persistent = false;
    };
  };
}
