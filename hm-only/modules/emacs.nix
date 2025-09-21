{ config, lib, pkgs, ... }:

{
  # emacs
  services.emacs.enable = true;
  # remove everything below if controlled by nix-doom-emacs; cf. in flakes.nix
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [ epkgs.vterm ];
  };
  home.file.".doom.d".source = ../../doom.d;
  home.packages = with pkgs; [
    emacs-all-the-icons-fonts
    pkgs.fira-code pkgs.roboto
    # libtool libvterm
  ];
}
