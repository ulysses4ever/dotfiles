{ config, lib, pkgs, ... }:

{
  # emacs
  services.emacs.enable = true;
  # remove everything below if controlled by nix-doom-emacs; cf. in flakes.nix
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk; # should be parameter
    extraPackages = epkgs: [ epkgs.vterm ];
  };
  home.file.".doom.d".source = ../../doom.d;
  home.packages = [ pkgs.emacs-all-the-icons-fonts ];

}
