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
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "netcup" "pixel7a" ];
          };
        };
      };
    };
  };

}
