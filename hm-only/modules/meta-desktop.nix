{ config, lib, pkgs, ... }:

{
  imports = [
    ./foot.nix
  ];

  # allows programs to see fonts installed via home.packages
  fonts.fontconfig.enable = true;

  # Dropbox
  # services.dropbox.enable = true;
}
