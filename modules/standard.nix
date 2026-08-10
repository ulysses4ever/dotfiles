{ config, lib, pkgs, ... }:

{
  imports =
    [
      ../packages.nix
      ../users/artem.nix
      ./basics.nix
      ./bootloader-efi.nix
      ./network.nix
      ./vpn-cu.nix
      ./desktop.nix
      ./get-cabal-head.nix
      ./nix.nix
    ];

}
