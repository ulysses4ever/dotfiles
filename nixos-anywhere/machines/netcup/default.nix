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
  security.acme.certs = {
    "web.pelenitsyn.top".email = "a@pelenitsyn.top";
  };
}
