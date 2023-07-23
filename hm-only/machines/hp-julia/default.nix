{ pkgs, ... }:
{
  imports = [
    ../default
    ../../modules/emacs.nix
    ../../modules/haskell.nix
    ../../modules/meta-desktop.nix
  ];

  home.packages = [ pkgs.julia_18 ];
}
