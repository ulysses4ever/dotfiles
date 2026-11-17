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
            # Through um690, as the other laptops have it; until 2026-11 its one
            # peer was Artem's Pixel 7a, dead since about 2026-09. um690 has to
            # list this laptop as well (machines/um690/syncthing.nix). Old
            # versions are kept as on lenovo-p14s, whose config says why.
            versioning = {
              type = "staggered";
              params.maxAge = toString (365 * 24 * 3600);
            };
            devices = [ "um690" ];
          };
        };
      };
    };
  };

}
