{ config, lib, pkgs, pkgsUnstable, ... }:

  let
    bindMount = dev: { device = dev; options = [ "bind" "nofail" ]; fsType = "ext4"; };
  in
{
  imports = [ ./matrix-bot.nix ];

  # Disable IPv6 in the hope to recover torrent access / XFinity port forwarding.
  networking.enableIPv6 = false;

  services.tailscale.enable = true;

  #
  # Jellyfin media server
  #
  services.jellyfin = {
    enable = true;
  };

  ##############################################################################
  #
  #  Low-tech galery in local network.
  #  It serves phone photos (obtained via Syncthing) through a simple HTML/JS page
  #

  # Nginx is cool but I can't figure out permissions: getting 403
  #
  # services.nginx = {
  #   enable = true;
  #   virtualHosts."127.0.0.1".locations."/artem-pics/" = {
  #     alias = "/home/artem/Pictures/Cell/pixel7a/Camera/";
  #     extraConfig = ''
  #       autoindex on;
  #     '';
  #   };
  # };

  services.httpd = {
    enable = true;
    virtualHosts."127.0.0.1" = {
      servedDirs =
        [
          {
            dir = "/home/artem/data/Pictures/pixel7a-artem/Camera";
            urlPath = "/artem-pics";
          }
          {
            dir = "/home/artem/data/Pictures/archive/HomeV";
            urlPath = "/hv";
          }
        ];
    };
    # Public vhost exposed via Cloudflare tunnel — only public_html.
    virtualHosts."www.pelenitsyn.site" = {
      documentRoot = "/home/artem/public_html";
    };
    # virtualHosts."localhost".enableUserDir = true; defunct due to https://github.com/NixOS/nixpkgs/pull/50857
  };

  systemd.tmpfiles.rules = [
    "d /mnt 0755 root users"
    "d /mnt/data 0755 root users"
    "d /mnt/data/artem 0755 artem users"
  ];
  systemd.user.tmpfiles.rules = [
    "d /media/immich/data 0755 immich users"
    "d /media/immich/archive 0755 immich users"
    "d /media/immich/cell 0755 immich users"
    "d /home/artem 0755 artem users"
    "d /home/artem/public_html 0755 artem users"
    "d /home/artem/Pictures 0755 artem users"
    "d /home/artem/Pictures/Cell 0755 artem users"
    "d /home/artem/Pictures/Cell/pixel7a 0755 artem users"
    "d /home/artem/Pictures/Cell/pixel7a/Camera 0755 artem users"
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 80 443 2283 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = true;


  ##############################################################################
  #
  #  Immich
  #

  # https://wiki.nixos.org/wiki/Immich
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    mediaLocation = "/media/immich/data";
  };
  fileSystems."/media/immich/data" = bindMount "/home/artem/data/Pictures/immich-data";
  fileSystems."/media/immich/archive" = bindMount "/home/artem/data/Pictures/archive";
  fileSystems."/media/immich/cell" = bindMount "/home/artem/data/Pictures//pixel7a-artem/Camera";
  fileSystems."/home/artem/data" = bindMount "/mnt/data/artem";

  ##############################################################################
  #
  # cloudflared's embedded SSH client only offers hmac-sha2-256/512 (non-etm),
  # so we add those alongside NixOS's default etm-only list.
  services.openssh.settings.Macs = [
    "hmac-sha2-512-etm@openssh.com"
    "hmac-sha2-256-etm@openssh.com"
    "umac-128-etm@openssh.com"
    "hmac-sha2-512"
    "hmac-sha2-256"
  ];

  # GitHub Actions self-hosted runners for the cu-cs-classes org.
  # All runners share a single PAT file at /var/lib/github-runner/pat; the
  # runner service exchanges the PAT for a short-lived registration token on
  # each startup, so the same file is reused across runners and survives
  # config changes. PAT scope: classic PAT with `admin:org`, or fine-grained
  # PAT with "Self-hosted runners: Read and write" on the cu-cs-classes org.
  services.github-runners = lib.genAttrs
    (map (i: "cu-cs-classes-${toString i}") (lib.range 1 8))
    (name: {
      enable = true;
      inherit name;
      url = "https://github.com/cu-cs-classes";
      tokenFile = "/var/lib/github-runner/pat";
      replace = true;
      # 26.05 pins 2.334.0, which GitHub's broker now refuses as deprecated:
      # the runner registers and connects, then dies on the first poll with a
      # 403. The store is read-only so the module must pass --disableupdate,
      # leaving no way to self-update — the version has to come from unstable.
      # Expect this to need bumping again every few months.
      package = pkgsUnstable.github-runner;
    });

  # Cloudflared
  #
  services.cloudflared = {
    enable = true;
    tunnels = {
      "2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19" = {
        credentialsFile = "${config.users.users.artem.home}/.cloudflared/2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19.json";
        default = "http_status:404";
        ingress = {
          "immich.pelenitsyn.site" = {
            service = "http://localhost:2283";
          };
          "ssh.pelenitsyn.site" = {
            service = "ssh://localhost:22";
          };
          "cabal-bot.pelenitsyn.site" = {
            service = "http://localhost:8765";
          };
          "www.pelenitsyn.site" = {
            service = "http://localhost:80";
          };
        };
      };
    };
  };


  # NGINX (for Photoprism but may be good for future)
  # services.nginx = {
  #   enable = true;
  #   # recommendedTlsSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedGzipSettings = true;
  #   recommendedProxySettings = true;
  #   clientMaxBodySize = "500m";
  #   virtualHosts = {
  #     # "pp.um690.local" = {
  #     #   # forceSSL = true;
  #     #   # enableACME = true;
  #     #   http2 = true;
  #     #   locations."/" = {
  #     #     proxyPass = "http://127.0.0.1:2342";
  #     #     proxyWebsockets = true;
  #     #     extraConfig = ''
  #     #       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #     #       proxy_set_header Host $host;
  #     #       proxy_buffering off;
  #     #     '';
  #     #   };
  #     # };
  #     "localhost" = {
  #       root = "/var/pics";
  #     };
  #   };
  # };



}
