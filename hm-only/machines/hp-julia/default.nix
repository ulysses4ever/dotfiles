{ pkgs, ... }:
{
  imports = [
    ../default
    ../../modules/emacs.nix
  ];

  home.packages = (import ../../../packages.nix) pkgs ++ [ pkgs.fira-code pkgs.roboto ];
}
