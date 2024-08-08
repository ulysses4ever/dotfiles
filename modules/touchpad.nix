{ config, lib, pkgs, ... }:

{
  # Enable touchpad support (enabled by default in most desktopManager).
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      tapping = true;
      middleEmulation = true;
    };
  };
}
