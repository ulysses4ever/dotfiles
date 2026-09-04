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
          "pixel7a" = { id = "B2UK2TS-WJQ224N-MZ6UUSL-AHRZ6Z5-VMJWTFV-KZGWIJD-T66PZAS-OFPHUA2"; };
          "pixel7a-julia" = { id = "LRW6ASR-XLL2XS6-Z47AFJ4-BRM5SAP-ZV3BV4T-LQDN3MC-C56TFIV-3M3BMQR"; };
          "hp-julia" = { id = "KVNEPPV-XFAYHIS-BMPKUZG-I2TRIPW-5ZUGNO4-2YN7BTQ-CGHAVKE-XQE6NA7"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "lenovo-p14s" "lenovo-x1ca-ap" "pixel7a" "hp-julia" ];
          };
          "Pixel7a-Pictures" = {
            id = "pixel_7a_j24u-photos";
            path = "/home/artem/data/Pictures/pixel7a-artem";
            devices = [ "pixel7a" ];
          };
          "Pixel7a-Julia-Photos" = {
            id = "pixel_7a_s1ud-photos";
            path = "/home/artem/data/Pictures/pixel7a-julia";
            devices = [ "pixel7a-julia" ];
          };
        };
      };
    };
  };

}
