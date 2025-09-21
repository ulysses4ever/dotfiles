{ pkgs, ... }:
{
  imports = [
    ../default
    ../../modules/emacs.nix
    ../../modules/haskell.nix
    ../../modules/meta-desktop.nix
  ];
}
