{ config, lib, pkgs, ... }:

{

  # Photoprism will use Mysql and maybe Nginx
  # fileSystems."/var/lib/private/photoprism/originals" =
  #   { device = "/data/originals";
  #     options = [ "bind" ];
  #   };
  # services.photoprism = {
  #   enable = true;
  #   port = 2342;
  #   # originalsPath = "/home/artem/Pictures/Photoprism";
  #   originalsPath = "/var/lib/private/photoprism/originals";
  #   address = "0.0.0.0";
  #   settings = {
  #     PHOTOPRISM_ADMIN_USER = "admin";
  #     PHOTOPRISM_ADMIN_PASSWORD = "123456";
  #     PHOTOPRISM_DEFAULT_LOCALE = "en";
  #     PHOTOPRISM_DATABASE_DRIVER = "mysql";
  #     PHOTOPRISM_DATABASE_NAME = "photoprism";
  #     PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
  #     PHOTOPRISM_DATABASE_USER = "photoprism";
  #     PHOTOPRISM_SITE_URL = "http://127.0.0.1:2342";
  #     PHOTOPRISM_SITE_TITLE = "My PhotoPrism";
  #   };
  # };

  # # MySQL
  # services.mysql = {
  #   enable = true;
  #   package = pkgs.mariadb;
  #   ensureDatabases = [ "photoprism" ];
  #   ensureUsers = [ {
  #     name = "photoprism";
  #     ensurePermissions = {
  #       "photoprism.*" = "ALL PRIVILEGES";
  #     };
  #   } ];
  # };

  # NGINX
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
  services.httpd = {
    enable = true;
    virtualHosts."localhost".enableUserDir = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

}
