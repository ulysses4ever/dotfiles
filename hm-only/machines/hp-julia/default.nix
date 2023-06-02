{ pkgs, ... }:
{
  imports = [ ../../../home.nix];
  home.packages = (import ../../../packages.nix) pkgs ++ [ pkgs.fira-code pkgs.roboto ];

  # Emacs
  programs.emacs.enable = true;
  home.file.".doom.d".source = ../../../doom.d;
}
