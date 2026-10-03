# cu-cs-grader.nix — the grader students test their work on, at
# grader.cu-cs-classes.site. The `next` branch of cu-cs-courses/pyret-grader
# until the switch; pyret-grader.nix is the instructors-only grader it will
# replace, and stays as it is until then.
#
# Two locks, one per half, and neither is this file's: /teach is behind a
# Cloudflare Access application naming the instructors, whose token serve.py
# checks as well; everything else answers nobody but a student signed in by a
# Brightspace launch. So, unlike pyret-grader, a request that reaches this
# service without Access in front of it still gets nothing. Create the Access
# application anyway before the rebuild that activates the ingress below.
{ config, pkgs, lib, ... }:

let
  checkout = "/home/artem/dev/cu-cs-grader";
  # Beside the grader's 8120 and course-status's 8121.
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

  # A restart is the deploy, as for pyret-grader: fast-forward only, and a
  # failed pull starts the old code rather than nothing.
  pull = pkgs.writeShellScript "cu-cs-grader-pull" ''
    cd ${checkout}
    exec ${pkgs.git}/bin/git pull --ff-only
  '';
in
{
  systemd.tmpfiles.rules = [ "d ${checkout} 0700 artem users -" ];

  # A user service for the reason pyret-grader is one: grade.py wraps every
  # run in `systemd-run --user --scope`, which needs a user manager. Linger is
  # already on, from pyret-grader.nix.
  systemd.user.services.cu-cs-grader = {
    description = "CMSC autograder for students, grader.cu-cs-classes.site";
    wantedBy = [ "default.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.ConditionUser = "artem";
    # openssh for the pull; the rest as for pyret-grader.
    path = with pkgs; [ nix bash coreutils git openssh ];
    serviceConfig = {
      ExecStartPre = "-${pull}";
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
      # Confining the supervisor would break the thing doing the confining;
      # each run is sandboxed in grade.sandbox(). See pyret-grader.nix.
    };
  };

  services.cloudflared.tunnels."2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19".ingress."grader.cu-cs-classes.site" = {
    service = "http://localhost:${toString port}";
  };
}
