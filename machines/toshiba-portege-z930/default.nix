# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, mname, ... }:

{
  imports =
    [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      # ./syncthing.nix

      # standard minus bootloader-efi + bootloader-grub
      ../../packages.nix
      ../../users/artem.nix
      ../../modules/basics.nix
      ../../modules/bootloader-grub.nix
      ../../modules/network.nix
      ../../modules/desktop.nix
      ../../modules/touchpad.nix
      ../../modules/get-cabal-head.nix
      ../../modules/nix.nix
      ../../modules/bluetooth.nix
    ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
