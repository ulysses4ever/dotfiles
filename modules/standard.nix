{ config, lib, pkgs, ... }:

{
  imports =
    [
      ../packages.nix
      ../users/artem.nix
      ./basics.nix
      ./network.nix
      ./desktop.nix
      ./touchpad.nix
      ./get-cabal-head.nix
      ./nix.nix
    ];

}
