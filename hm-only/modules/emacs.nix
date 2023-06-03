{ config, lib, pkgs, ... }:

{
  # emacs
  services.emacs.enable = true;
  # remove if controlled by nix-doom-emacs; cf. in flakes.nix
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk;
    extraPackages = epkgs: [ epkgs.vterm ];
  };
  home.file.".doom.d".source = ../../../doom.d;
}
