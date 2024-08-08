{ config, lib, pkgs, mname, ... }:

{
  networking = {
    hostName = "${mname}"; # Define your hostname.

    # Either NetworkManager or wireless service -- not both! (they conflict)
    networkmanager.enable = true;
    #wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    #networkmanager.wifi.backend = "iwd";
    #wireless.iwd.settings.General.UseDefaultInterface = true;

    useDHCP = false; # blanket true is not allowed anymore (they say)
    interfaces.enp0s31f6.useDHCP = true;
    interfaces.wlan0.useDHCP = true; # fix iwd race
    #interfaces.wlp0s20f3.useDHCP = false; # fix iwd race
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Announce myself as $hostname.local in a local network and help others to do the same
  # https://github.com/NixOS/nixpkgs/issues/98050#issuecomment-1471678276
  services.resolved.enable = true;
  networking.networkmanager.connectionConfig."connection.mdns" = 2;
  services.avahi.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


}
