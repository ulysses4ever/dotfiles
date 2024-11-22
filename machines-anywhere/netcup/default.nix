{ pkgs, config, ... }: {
  # Local network configuration for netcup servers
  imports = [ ./networking.nix ];

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

    virtualHosts."cloud.pelenitsyn.top" = {
#      enableACME = true;
#      forceSSL = true;
#      root = "/var/www";
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
  #
  # Syncthing
  #
  services = {
    syncthing = {
      enable = true;
      user = "artem";
      overrideDevices = true;
      overrideFolders = true;
      configDir = "/home/artem/.config/syncthing";
      settings = {
        devices = {
          "lenovo-p14s" = { id = "GFAZZKL-NSQ2B4A-EGNSRCO-UWFEYSL-3G2FSX2-I7KNPQ4-J2R5SH6-272BYA5"; };
          "pixel7a" = { id = "B2UK2TS-WJQ224N-MZ6UUSL-AHRZ6Z5-VMJWTFV-KZGWIJD-T66PZAS-OFPHUA2"; };
          "um690" = { id = "HQXNESL-7EYYOWV-5TLW4MV-G7FISYB-HU777OO-N4IJ3PU-3DYRMGA-2CMSAQ3"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "lenovo-p14s" "pixel7a" "um690" ];
          };
        };
      };
    };
  };

  ##############################################
  #
  # Nextcloud with PSQL
  #

  services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud28;
      hostName = "cloud.pelenitsyn.top";
      # Enable built-in virtual host management
      # Takes care of somewhat complicated setup
      # See here: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-apps/nextcloud.nix#L529
      configureRedis = true;

      # Use HTTPS for links
      https = true;

#      extraApps = with config.services.nextcloud.package.packages.apps; {
#        inherit onlyoffice;
#      };
#      extraAppsEnable = true; 

      # Auto-update Nextcloud Apps
      # autoUpdateApps.enable = true;
      # Set what time makes sense for you
      # autoUpdateApps.startAt = "05:00:00";

      config = {
        # Further forces Nextcloud to use HTTPS
#        overwriteProtocol = "https";

        # Nextcloud PostegreSQL database configuration, recommended over using SQLite
#        dbtype = "pgsql";
#        dbuser = "nextcloud";
#        dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
#        dbname = "nextcloud";
#        dbpassFile = "/etc/nextcloud-db-pass";

        adminpassFile = "/etc/nextcloud-pass";
        adminuser = "admin";
   };
  };

#  services.postgresql = {
#      enable = true;
#
#      # Ensure the database, user, and permissions always exist
#      ensureDatabases = [ "nextcloud" ];
#      ensureUsers = [
#       { name = "nextcloud";
#         ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
#       }
#      ];
#  };
#
#  systemd.services."nextcloud-setup" = {
#      requires = ["postgresql.service"];
#      after = ["postgresql.service"];
#  };

}
