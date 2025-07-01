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
          "netcup" = { id = "U25H2L7-KJY7IXJ-HHD2D76-4LBMTBZ-2CJE2NM-DBZO2V7-IUVFGPI-JGBXRQA"; };
          "pixel7a" = { id = "B2UK2TS-WJQ224N-MZ6UUSL-AHRZ6Z5-VMJWTFV-KZGWIJD-T66PZAS-OFPHUA2"; };
          "pixel7a-julia" = { id = "LRW6ASR-XLL2XS6-Z47AFJ4-BRM5SAP-ZV3BV4T-LQDN3MC-C56TFIV-3M3BMQR"; };
          "hp-julia" = { id = "KVNEPPV-XFAYHIS-BMPKUZG-I2TRIPW-5ZUGNO4-2YN7BTQ-CGHAVKE-XQE6NA7"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "netcup" "pixel7a" "hp-julia" ];
          };
          "Pixel7a-Pictures" = {
            id = "pixel_7a_j24u-photos";
            path = "/home/artem/Pictures/Cell/pixel7a";
            devices = [ "pixel7a" ];
          };
          "Pixel7a-Julia-Photos" = {
            id = "pixel_7a_s1ud-photos";
            path = "/home/artem/Pictures/Pixel7a-Julia-Photos";
            devices = [ "pixel7a-julia" ];
          };
        };
      };
    };
  };

}
