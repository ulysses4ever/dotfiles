{ lib, ... }:
{
  boot.loader.grub.devices = [ "/dev/nvme0n1" ];
  disko.devices = import ../../disk-config.nix {
    lib = lib;
    disks = [ "/dev/nvme0n1" ];
  };
  networking = {
    networkmanager.enable = true;
    firewall.enable = false;

    # Announce myself as $hostname.local in a local network and help others to do the same
    # https://github.com/NixOS/nixpkgs/issues/98050#issuecomment-1471678276
    services.resolved.enable = true;
    networking.networkmanager.connectionConfig."connection.mdns" = 2;
    services.avahi.enable = true;
  };
}
