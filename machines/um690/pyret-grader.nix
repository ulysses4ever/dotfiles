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
  systemd.services.grader-tailnet = {
    description = "Expose the Pyret autograder on the tailnet";
    wants = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # tailscaled is up before it is authenticated; serve fails until then.
      Restart = "on-failure";
      RestartSec = 10;

      # serve config lives in tailscaled's state, not here, so it survives
      # across rebuilds and would otherwise accumulate stale handlers on this
      # port. Reset first so the node's config is exactly what this unit
      # declares. um690 serves nothing else this way; revisit if it ever does.
      ExecStartPre = "-${config.services.tailscale.package}/bin/tailscale serve reset";

      # --tcp, not --http. Serve's HTTP mode is a reverse proxy that routes on
      # the Host header and only answers for this node's MagicDNS names, so a
      # browser arriving through `ssh -L` — which sends Host: localhost:8120 —
      # gets a 404. Raw TCP passthrough does not inspect the request at all.
      # (--https is the default mode and is wrong here for the same reason,
      # plus it would demand a certificate for a hostname the client isn't using.)
      # --yes suppresses a confirmation prompt that would hang the unit.
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --tcp=${toString port} tcp://127.0.0.1:${toString port}";
    };
  };
}

