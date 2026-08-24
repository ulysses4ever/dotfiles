{ config, pkgs, ... }:

let
  mirrorScript = pkgs.writeShellApplication {
    name = "cu-cs-mirror";
    # config.nix.package rather than pkgs.nix so the client matches the daemon.
    runtimeInputs = [ pkgs.git pkgs.rsync config.nix.package ];
    text = builtins.readFile ./cu-cs-mirror.sh;
  };
in
{
  # Apache vhost for the local mirror.
  services.httpd.virtualHosts."cu-cs-courses.pelenitsyn.site" = {
    documentRoot = "/home/artem/cu-cs-courses/www";
  };

  # Route the hostname through the existing Cloudflare tunnel.
  services.cloudflared.tunnels."2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19".ingress."cu-cs-courses.pelenitsyn.site" = {
    service = "http://localhost:80";
  };

  systemd.tmpfiles.rules = [
    "d /home/artem/cu-cs-courses 0755 artem users"
    "d /home/artem/cu-cs-courses/www 0755 artem users"
  ];

  # Hourly mirror of all cu-cs-courses GitHub repos → local Apache docroot.
  # Tolerates GitHub being down: sync_repo builds from the local checkout
  # instead of pulling, so the last-known-good content stays live.
  systemd.services.cu-cs-mirror = {
    description = "Mirror cu-cs-courses sites from GitHub";
    serviceConfig = {
      Type = "oneshot";
      User = "artem";
      ExecStart = "${mirrorScript}/bin/cu-cs-mirror";
      Environment = [
        "HOME=/home/artem"
        "NIX_REMOTE=daemon"
      ];
    };
  };

  systemd.timers.cu-cs-mirror = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}
