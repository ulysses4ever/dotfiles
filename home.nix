{ config, pkgs, ... }:

let
  emacs-overlay = builtins.fetchTarball "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
  pkgs = import <nixpkgs> { overlays = [ (import emacs-overlay) ]; };
  doom-emacs = pkgs.callPackage (builtins.fetchTarball {
    url = https://github.com/vlaci/nix-doom-emacs/archive/master.tar.gz;
  }) {
    doomPrivateDir = /home/artem/Dropbox/config/doom.d;  # Directory containing your config.el init.el
    emacsPackages = pkgs.emacsPackagesFor pkgs.emacsPgtk;
  };
in {


  # AUTO GENERATED
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "artem";
  home.homeDirectory = "/home/artem";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";
  # ENF OF AUTO GENERATED

  home.packages = [ doom-emacs ];
  home.file.".emacs.d/init.el".text = ''
      (load "default.el")
  '';

#  services.gpg-agent = {
 #     enable = true;
 #     defaultCacheTtl = 1800;
 #     enableSshSupport = true;
 #   };
}
