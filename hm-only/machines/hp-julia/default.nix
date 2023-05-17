{ pkgs, ... }:
{
  imports = [ ../../../home.nix];
  home.packages = (import ../../../packages.nix) pkgs ++ [ pkgs.fira-code ];
}
