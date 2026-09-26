# pyret-grader.nix — Pyret autograder. serve.py has no auth of its own, so it
# stays on loopback and is reached through two fronts that each authenticate:
# Cloudflare Access on grader.pelenitsyn.site, and the tailnet via tailscale serve.
{ config, pkgs, lib, ... }:

let
  checkout = "/home/artem/dev/pyret-grader";
  port = 8120;

  # nix-shell needs a shell to run in and the unit needs one command to
  # exec, so the two meet in a script rather than in ExecStart quoting.
  # shell.nix pins its own nixpkgs, so NIX_PATH is deliberately not set.
  start = pkgs.writeShellScript "pyret-grader" ''
    cd ${checkout}
    exec ${pkgs.nix}/bin/nix-shell --run "./serve.py --port ${toString port}"
  '';

  # A restart is the deploy. The checkout is brought up to origin/main before
  # serve.py starts, so after a push `systemctl --user restart pyret-grader`
  # is the whole procedure — Artem, 2026-09-25, after a release sat unpulled
  # on the box for three days. Fast-forward only, so the box never merges;
  # the `-` on ExecStartPre below lets a failed pull (no network, a diverged
  # checkout) log and start the old code rather than take the grader down.
  pull = pkgs.writeShellScript "pyret-grader-pull" ''
    cd ${checkout}
    exec ${pkgs.git}/bin/git pull --ff-only
  '';
in
{
  # Student names, code and grades land in ${checkout}/runs. This box also
  # runs eight GitHub Actions runners sharing an org PAT, so the mode is
  # doing real work: keep it 0700 and keep the directory out of any path
  # those runners check out into.
  systemd.tmpfiles.rules = [ "d ${checkout} 0700 artem users -" ];

  # grade.py wraps every submission in `systemd-run --user --scope`, which
  # needs a user manager and its session bus. Linger starts one at boot, so
  # the grader survives a reboot with nobody logged in.
  users.users.artem.linger = true;

  systemd.user.services.pyret-grader = {
    description = "CMSC 120 Pyret autograder";
    wantedBy = [ "default.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    # systemd.user.services is defined for every user on the machine. This is
    # the only thing stopping it from running under any other account that
    # gets a session.
    unitConfig.ConditionUser = "artem";

    # openssh is for the pull: the remote is git@github.com and git looks for
    # ssh on PATH, which is this list and nothing else.
    path = with pkgs; [ nix bash coreutils git openssh ];

    serviceConfig = {
      ExecStartPre = "-${pull}";
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
      # No ProtectHome/PrivateTmp/ReadOnlyPaths here on purpose. This unit's
      # entire job is to spawn bwrap inside a transient scope; confining the
      # supervisor breaks the thing doing the confining, and the isolation
      # that matters is applied per submission in grade.sandbox().
    };
  };

  # The university firewall DNS-sinkholes the whole pelenitsyn.site zone, so
  # grader.pelenitsyn.site does not resolve on campus and the Cloudflare path
  # is unusable from there. This publishes the same service on the tailnet as a
  # second, independent way in: instructors on campus ssh to a box inside the
  # university network and forward ${toString port} from here.
  #
  # Deliberately a separate front rather than binding serve.py to the tailnet
  # address. Binding it there would take it off loopback, forcing cloudflared
  # to reach it over the tailnet too, and a tailscaled outage would then break
  # the off-campus path as well. Proxying keeps the two paths independent.
  #
  # This was a `grader-tailnet` unit of its own, resetting the serve config
  # before declaring this port, under a comment reading "um690 serves nothing
  # else this way; revisit if it ever does." It does now — course-status.nix is
  # on 8121 — and `reset` clears the node's whole config rather than one port,
  # so two such units would take turns deleting each other's handler. The reset
  # and every declaration moved into tailnet-serve.nix together; its header has
  # the reasoning, including why unit ordering would not have been a fix.
  um690.tailnetServe.tcp."${toString port}" = "tcp://127.0.0.1:${toString port}";
}
