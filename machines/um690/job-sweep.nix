# job-sweep.nix — the weekly job sweep, started every Friday night and checked
# on Saturday evening. Artem, 2026-11-22: "a systemd service that would message
# this running session to run the sweep once a week friday midnight. if fails,
# let it post an issue on our repo using gh".
#
# Nothing here runs the sweep. The job-search Claude session, the standing one
# in ~/edu/academic-job-application, does that by its own procedure,
# weekly-sweep.md; this only tells it to start, with
# scripts/sweep-trigger.py there, which carries the message the way edu-fetch.nix
# carries the courses' news: `claude -p` with haiku and SendMessage as its only
# tool. The session opens a GitHub issue if the sweep fails part way; the
# script opens one if there is no session to tell or the message does not go
# (job-sweep-start), and if no `sweep:` commit has reached GitHub by Saturday
# evening (job-sweep-check). `journalctl -u job-sweep-start -u job-sweep-check`
# says what each did.
#
# Both run as artem, for gh's login and the sessions' sockets, and read the
# repository without writing to it. Persistent: a Friday night with the machine
# off starts the sweep at the next boot.
{ config, lib, pkgs, pkgsUnstable, ... }:

let
  repo = "/home/artem/edu/academic-job-application";
  unit = mode: description: {
    inherit description;
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.gh pkgs.git pkgsUnstable.claude-code ];
    serviceConfig = {
      Type = "oneshot";
      User = "artem";
      # XDG_RUNTIME_DIR is where Claude sessions keep the sockets a message
      # reaches them by, and a system unit is given none of its own.
      Environment = [ "HOME=/home/artem" "XDG_RUNTIME_DIR=/run/user/1000" ];
      ExecStart = "${pkgs.python3}/bin/python3 -u ${repo}/scripts/sweep-trigger.py ${mode}";
      ReadOnlyPaths = [ repo ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
  timer = when: {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = when; Persistent = true; };
  };
in
{
  systemd.services.job-sweep-start = unit "start" "Tell the job-search Claude session to run the weekly sweep";
  systemd.services.job-sweep-check = unit "check" "Open an issue if this week's job sweep has not reached GitHub";
  # "Friday midnight": the first minutes of Saturday, in the machine's time zone.
  systemd.timers.job-sweep-start = timer "Sat *-*-* 00:05:00";
  systemd.timers.job-sweep-check = timer "Sat *-*-* 18:00:00";
}
