{
  imports = [ ../../../machines/netcup/networking.nix ];
  boot.loader.grub.devices = [ "/dev/vda" ];
}
