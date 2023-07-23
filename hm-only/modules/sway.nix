{ config, lib, pkgs, ... }:

{
  # Sway
  # TODO: replace NixOS module with this HM module:
  # wayland.windowManager.sway = {
  #   enable = true;
  # }
  xdg.configFile."sway/config".source = ../../sway/config;
  xdg.configFile."sway/machine-dependent".source =
    ../../machines/lenovo-p14s/sway/machine-dependent;  # TODO: how to parametrize with
                                                        #       machine name?
  xdg.configFile.waybar.source = ./waybar;

}
