# edu-fetch.nix — the three courses' Journals and hand-ins, fetched as they
# come due, and each course's standing Claude session told what came in:
# ~/edu/scripts/fetch.py --serve, which sleeps until twenty minutes after a
# class ends or five minutes after a deadline, reading both off the course
# sites, then fetches what is due and skips what it already has; fetch.py's
# own docstring says what, where it lands and why. Artem, 2026-10-13: a script
# rather than `claude -p` for the fetching, the Journal right after class, and
# "Why not just at the times when class or deadline passed?" -- until then this
# was a timer every fifteen minutes from 7:00 to midnight.
#
# It runs as artem, for the reason brightspace-keepalive.nix gives, and leans
# on the Brightspace session that unit keeps alive. A dead session is a failed
# run: a journal line (`journalctl -u edu-fetch -n 20`), a FAILED line at the
# top of the status report, and a retry fifteen minutes later, which the
# keep-alive's repair from Firefox usually makes good.
{ config, lib, pkgs, pkgsUnstable, ... }:

let
  edu = "/home/artem/edu";
  # PyYAML for the course sites' own files; lz4 for brightspace.py, which
  # re-reads Firefox's session store when the session has died (see
  # brightspace-keepalive.nix).
  python = pkgs.python3.withPackages (ps: [ ps.lz4 ps.pyyaml ]);
in
{
  systemd.services.edu-fetch = {
    description = "Fetch the courses' Journals and hand-ins as they come due, and tell the class sessions";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    # `gh teacher download` clones through gh and git. gh-teacher itself is a
    # static binary among artem's gh extensions, found under his HOME; fetch.py
    # turns GitHub's ssh URLs into HTTPS for its own runs, since a unit has no
    # ssh agent, and git's credential helper there is gh. claude carries each
    # message to a class session (`claude -p` with SendMessage) and finds the
    # session (`claude agents --json`): the same package packages.nix installs.
    path = [ pkgs.gh pkgs.git pkgs.openssh pkgsUnstable.claude-code ];

    serviceConfig = {
      Type = "simple";
      User = "artem";
      # XDG_RUNTIME_DIR is where Claude sessions keep the sockets a message
      # reaches them by, and a system unit is given none of its own.
      Environment = [ "HOME=/home/artem" "XDG_RUNTIME_DIR=/run/user/1000" ];
      ExecStart = "${python}/bin/python3 -u ${edu}/scripts/fetch.py --serve";
      # An edit to fetch.py is taken up by the script itself, at its next
      # wake; a crash comes back a minute later and catches up what it missed.
      Restart = "always";
      RestartSec = "1min";
      # The checkouts are working data and the script is edited by hand, so the
      # unit cannot write to them. What it fetches goes through each course's
      # dropbox link into ~/Dropbox, outside this path, its state into
      # ~/.local/state/edu-fetch, and the messenger's transcripts into ~/.claude.
      ReadOnlyPaths = [ edu ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
