{ config, lib, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./fish.nix
    ./neovim.nix
  ];

  programs.bat = {
    enable = true;
    config.theme = "GitHub";
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
  };

  home.file.".ghci".source = ../../.ghci;
}
