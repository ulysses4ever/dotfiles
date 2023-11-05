{ pkgs, ... }: {
  # Local network configuration for netcup servers
  imports = [ ../../../machines/netcup/networking.nix ];

  # Disks
  boot.loader.grub.devices = [ "/dev/vda" ];
  disko.devices = import ./disk-config.nix {};

  # Networking in the outer world
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  security.acme.acceptTerms = true;

  # Nginx config
  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."web.pelenitsyn.top" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www";
    };
  };

  # Artem, 2023-11-01:
  # I failed to figure out how to serve $USER/public_html proper
  users.users.artem.homeMode = "750";
  users.users.artem.extraGroups = [ "nginx" ];
  users.groups."nginx" = {};
#  services.nginx.virtualHosts."web.pelenitsyn.top".locations = {
#    "~ ^/~artem(/.*)?$" = {
#      alias = "/var/www/artem$1";
#      extraConfig = ''
#        autoindex on;
#        index     index.html;
#      '';
#    };
#  };
#  systemd.services.nginx.serviceConfig.ProtectHome = lib.mkForce false;
#  systemd.services.nginx.serviceConfig.ProtectSystem = lib.mkForce false;
#  systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/home/" ];
#       locations."~ ^/~(.+?)(/.*)?$" = {
#         alias = "/home/$1/public_html$2;";
#       };
##############################################
# end of nginx serving $USER/public_html experiments

  security.acme.certs = {
    "web.pelenitsyn.top".email = "a@pelenitsyn.top";
  };

  # basic comforts
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
##############################################
  # Nextcloud with PSQL
  services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud27;
      hostName = "cloud.pelenitsyn.top";
      # Enable built-in virtual host management
      # Takes care of somewhat complicated setup
      # See here: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-apps/nextcloud.nix#L529
      nginx.enable = true;
      configureRedis = true;

      # Use HTTPS for links
      https = true;

      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit onlyoffice;
      };
      extraAppsEnable = true; 

      # Auto-update Nextcloud Apps
      # autoUpdateApps.enable = true;
      # Set what time makes sense for you
      # autoUpdateApps.startAt = "05:00:00";

      config = {
        # Further forces Nextcloud to use HTTPS
        overwriteProtocol = "https";

        # Nextcloud PostegreSQL database configuration, recommended over using SQLite
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
        dbname = "nextcloud";
        dbpassFile = "/etc/nextcloud-db-pass";

        adminpassFile = "/etc/nextcloud-pass";
        adminuser = "admin";
   };
  };

  services.postgresql = {
      enable = true;

      # Ensure the database, user, and permissions always exist
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
       { name = "nextcloud";
         ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
       }
      ];
  };

  systemd.services."nextcloud-setup" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
  };

}
