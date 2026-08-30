# pyret-grader.nix — Pyret autograder, reachable only through
# Cloudflare Access on grader.pelenitsyn.site. serve.py has no auth of its own.
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
    # the only thing stopping it fr Jump to bottom (ctrl+End) ↓ her account
    # that gets a session.
    unitConfig.ConditionUser = "artem";

    path = with pkgs; [ nix bash coreutils git ];

    serviceConfig = {
      ExecStart = start;
      Restart = "on-failure";
      RestartSec = 5;
      # No ProtectHome/PrivateTmp/ReadOnlyPaths here on purpose. This unit's
      # entire job is to spawn bwrap inside a transient scope; confining the
      # supervisor breaks the thing doing the confining, and the isolation
      # that matters is applied per submission in grade.sandbox().
    };
  };
}

