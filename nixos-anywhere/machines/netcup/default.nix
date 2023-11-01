{
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
}
