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
          "pixel7a" = { id = "B2UK2TS-WJQ224N-MZ6UUSL-AHRZ6Z5-VMJWTFV-KZGWIJD-T66PZAS-OFPHUA2"; };
          "um690" = { id = "HQXNESL-7EYYOWV-5TLW4MV-G7FISYB-HU777OO-N4IJ3PU-3DYRMGA-2CMSAQ3"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "pixel7a" "um690" ];
          };
        };
      };
    };
  };

}
