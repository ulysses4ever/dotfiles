{ pkgs, ... }:
{
  imports = [
    ../default
    ../../modules/emacs.nix
    ../../modules/meta-desktop.nix
  ];

  home.packages = (import ../../../packages.nix) pkgs ++ [ pkgs.fira-code pkgs.roboto ];
}
