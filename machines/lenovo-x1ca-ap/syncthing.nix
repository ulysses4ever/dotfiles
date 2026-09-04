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
          "um690" = { id = "HQXNESL-7EYYOWV-5TLW4MV-G7FISYB-HU777OO-N4IJ3PU-3DYRMGA-2CMSAQ3"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "um690" ];
          };
        };
      };
    };
  };

}
