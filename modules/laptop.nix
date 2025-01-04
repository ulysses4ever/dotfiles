{ config, lib, pkgs, ... }:

{

  imports =
    [
      ./bluetooth.nix
      ./touchpad.nix
    ];

  # Laptop power button to suspend
  services.logind.extraConfig = "HandlePowerKey=suspend";

  # Brightness via Fn keys
  services.illum.enable = true;
}
