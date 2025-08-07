{ config, lib, pkgs, ... }:

  let
    bindMount = dev: { device = dev; options = [ "bind" "nofail" ]; };
  in
{

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
  fileSystems."/media/immich/data" = bindMount "/home/artem/.local/state/immich";
  fileSystems."/media/immich/archive" = bindMount "/home/artem/data/Pictures/archive";
  fileSystems."/media/immich/cell" = bindMount "/home/artem/data/Pictures//pixel7a-artem/Camera";
  fileSystems."/home/artem/data" = bindMount "/mnt/data/artem";

  ##############################################################################
  #
  # Cloudflared
  #
  # environment.systemPackages = [pkgs.cloudflared];
  # services.cloudflared = {
  #   enable = true;
  #   tunnels = {
  #     "2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19" = {
  #       credentialsFile = "${config.users.users.artem.home}/.cloudflared/artem-tunnel.config.json";
  #       default = "http_status:404";
  #       ingress = {
  #         "*.pelenitsyn.site" = {
  #          service = "http://localhost:2283";
  #         };
  #       };
  #     };
  #   };
  # };


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
