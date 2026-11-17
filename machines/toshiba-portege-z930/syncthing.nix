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
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            # Its one peer was Artem's Pixel 7a, gone since about 2026-09, so
            # this Dropbox syncs with nothing until another device is added
            # here (um690, say, as lenovo-p14s has).
            devices = [ ];
          };
        };
      };
    };
  };

}
