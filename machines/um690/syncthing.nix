{ config, lib, pkgs, ... }:

{
  services = {
    syncthing = {
      enable = true;
      user = "artem";
      overrideDevices = true;
      overrideFolders = true;
      configDir = "/home/artem/.config/syncthing";
      settings = {
        devices = {
          "lenovo-p14s" = { id = "GFAZZKL-NSQ2B4A-EGNSRCO-UWFEYSL-3G2FSX2-I7KNPQ4-J2R5SH6-272BYA5"; };
          "lenovo-x1ca-ap" = { id = "MC6MAHR-7INCMLV-7LO6WQ4-MZKRW7L-SKBNCS2-QOS7LRE-FT5AMOL-DOV64AO"; };
          "hp-julia" = { id = "KVNEPPV-XFAYHIS-BMPKUZG-I2TRIPW-5ZUGNO4-2YN7BTQ-CGHAVKE-XQE6NA7"; };
          "toshiba-portege-z930" = { id = "HOY6BJE-W4VUQFD-P4KJKMW-LON6U7A-WBTBVWE-4YPDJFE-CRKB3GJ-HMABJQC"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "lenovo-p14s" "lenovo-x1ca-ap" "hp-julia" "toshiba-portege-z930" ];
          };
          # The phones' camera folders are gone (2026-11-17): photos reach the
          # server through the Immich app only. Artem's Pixel 7a died around
          # 2026-09; what its folder held is in Immich, the 32 files Immich
          # lacked are in data/Pictures/archive, and the ThinGallery page that
          # showed it is in Dropbox/scripts. Julia turned Syncthing off on her
          # Pixel 7a; what her folder held is in Immich too, except 42 files
          # (videos over 100 MB, which the Cloudflare tunnel refuses, and some
          # edits) waiting in data/Pictures/julia-to-upload until they are.
        };
      };
    };
  };

}
