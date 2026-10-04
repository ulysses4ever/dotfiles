# cu-cs-grader.nix — the autograder, at grader.cu-cs-classes.site: students
# test their work on it, and instructors grade on it under /teach. The `main`
# branch of cu-cs-courses/pyret-grader, v2.0 on. It replaced pyret-grader.nix,
# the instructors-only grader at grader.pelenitsyn.site, which was
# decommissioned 2026-10-04 — git history has it.
#
# Two locks, one per half, and neither is this file's: /teach is behind a
# Cloudflare Access application naming the instructors, whose token serve.py
# checks as well; everything else answers nobody but a student signed in by a
# Brightspace launch. So, unlike the old grader, a request that reaches this
# service without Access in front of it still gets nothing. Create the Access
# application anyway before the rebuild that activates the ingress below.
{ config, pkgs, lib, ... }:

let
  checkout = "/home/artem/dev/cu-cs-grader";
  # Beside course-status's 8121; 8120 was the old grader's.
  port = 8122;

  # Pyret runs at once. Eight rather than grade.py's three: eighty students
  # arriving in the last five minutes waited 97 seconds for the median result
  # with three, 24 with six, 12 with eight — and 12 with ten, and 15 with
  # twelve, where the CPU is full and every run slows. stress.py on the branch,
  # and its README's "At a deadline", 2026-10-03; eight is Artem's pick. The
  # cost is the CPU during a rush, 76% at the busiest, and eight runs that
  # could each reach the 2 GB cap at once; the most seen together was 3.8 GB.
  slots = 8;

  # The state directory — settings, database, every student's test runs — is
  # inside the checkout, which tmpfiles keeps at 0700; see store.py. It holds
  # grader.yml, written by hand, with the LTI secret: serve.py refuses to start
  # unless that file is 0600.
  start = pkgs.writeShellScript "cu-cs-grader" ''
    cd ${checkout}
    exec ${pkgs.nix}/bin/nix-shell --run "./serve.py --port ${toString port} --state ${checkout}/state --slots ${toString slots}"
  '';

  # A restart is the deploy: fast-forward only, and a failed pull starts the
  # old code rather than nothing.
  pull = pkgs.writeShellScript "cu-cs-grader-pull" ''
    cd ${checkout}
    exec ${pkgs.git}/bin/git pull --ff-only
  '';
in
{
  systemd.tmpfiles.rules = [ "d ${checkout} 0700 artem users -" ];

  # A user service on purpose: grade.py wraps every run in `systemd-run
  # --user --scope`, which needs a user manager and its session bus — as a
  # system service that call fails on every run, and the class scores zero.
  # Linger starts the user manager at boot, so the grader survives a reboot
  # with nobody logged in. It came with pyret-grader.nix, and stays with the
  # grader now that the module is gone.
  users.users.artem.linger = true;
  systemd.user.services.cu-cs-grader = {
    description = "CMSC autograder for students, grader.cu-cs-classes.site";
    wantedBy = [ "default.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.ConditionUser = "artem";
    # nix-shell and the shell it runs; git and openssh for the pull.
    path = with pkgs; [ nix bash coreutils git openssh ];
    serviceConfig = {
      ExecStartPre = "-${pull}";
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
      # No ProtectHome/PrivateTmp/ReadOnlyPaths, on purpose: confining the
      # supervisor would break the thing doing the confining, and each run is
      # sandboxed in grade.sandbox().
    };
  };

  services.cloudflared.tunnels."2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19".ingress."grader.cu-cs-classes.site" = {
    service = "http://localhost:${toString port}";
  };
}
