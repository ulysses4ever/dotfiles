{ config, lib, pkgs, ... }:

{

  # vscode
  # this is embarassing but I still don't get how to build a NixOS config
  # that (declaratively) allows unfree modules in home-manager
  # programs.vscode = {
  #   enable = true;
  #   extensions = with pkgs.vscode-extensions; [
  #     dracula-theme.theme-dracula
  #     vscodevim.vim
  #     yzhang.markdown-all-in-one
  #   ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
  #     {
  #       name = "language-julia";
  #       publisher = "julialang";
  #       version = "1.45.1";
  #       sha256 = "PC+f3mEaiHMYvS5nUmB8e4596Cx2PCBfxKbrE8tFLa4=";
  #       #         1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g
  #     }
  #   ];
  # };

  # Sway
  xdg.configFile."sway/config".source = ./sway/config;
  xdg.configFile."sway/machine-dependent".source =
    ./machines/lenovo-p14s/sway/machine-dependent;      # TODO: how to parametrize with
                                                        #       machine name?
  xdg.configFile.waybar.source = ./waybar;

}
