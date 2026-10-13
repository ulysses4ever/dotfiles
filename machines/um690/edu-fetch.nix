# edu-fetch.nix — the three courses' Journals and hand-ins, fetched on a timer:
# ~/edu/scripts/fetch.py every fifteen minutes through the day. A run fetches
# the Journal of each class that ended twenty minutes ago or more, and each
# assignment past its deadline -- Brightspace folders in 120 and 240, Classroom
# 50 repositories in 230 -- and skips whatever it already has; fetch.py's own
# docstring says what, where it lands and why. Artem, 2026-10-13: a script on a
# timer rather than `claude -p`, with the Journal right after class.
#
# It runs as artem, for the reason brightspace-keepalive.nix gives, and leans
# on the Brightspace session that unit keeps alive. A dead session is a failed
# run: a journal line (`journalctl -u edu-fetch -n 20`), a FAILED line at the
# top of the status report, and a retry fifteen minutes later, which the
# keep-alive's repair from Firefox usually makes good.
{ config, lib, pkgs, ... }:

let
  edu = "/home/artem/edu";
  # PyYAML for the course sites' own files; lz4 for brightspace.py, which
  # re-reads Firefox's session store when the session has died (see
  # brightspace-keepalive.nix).
  python = pkgs.python3.withPackages (ps: [ ps.lz4 ps.pyyaml ]);
in
{
  systemd.services.edu-fetch = {
    description = "Fetch the courses' Journals and hand-ins";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    # `gh teacher download` clones through gh and git. gh-teacher itself is a
    # static binary among artem's gh extensions, found under his HOME; fetch.py
    # turns GitHub's ssh URLs into HTTPS for its own runs, since a unit has no
    # ssh agent, and git's credential helper there is gh.
    path = [ pkgs.gh pkgs.git pkgs.openssh ];

    serviceConfig = {
      Type = "oneshot";
      User = "artem";
      Environment = [ "HOME=/home/artem" ];
      ExecStart = "${python}/bin/python3 ${edu}/scripts/fetch.py";
      # The checkouts are working data and the script is edited by hand, so the
      # unit cannot write to them. What it fetches goes through each course's
      # dropbox link into ~/Dropbox, outside this path, and its state into
      # ~/.local/state/edu-fetch.
      ReadOnlyPaths = [ edu ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      # A first download of a big assignment, or of every repository of one.
      TimeoutStartSec = "20min";
    };
  };

  systemd.timers.edu-fetch = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Through the day only: the last class ends at 3:50, the Journal is
      # fetched twenty minutes after a class, and a deadline at 23:59 is
      # fetched by the first run of the morning.
      OnCalendar = "*-*-* 07..23:00/15";
      AccuracySec = "1min";
      # A missed run is caught up by the next: fetch.py looks back over the
      # last three days' classes and the last week's deadlines.
      Persistent = false;
    };
  };
}
