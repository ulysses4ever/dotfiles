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
            # The undo for https://dropbox.pelenitsyn.site/ (um690's dropbox-web.nix),
            # where a file can be edited, replaced by an upload or deleted. Syncthing
            # keeps old copies only of changes that arrive from another device, so um690
            # can't keep them of its own edits; the laptops do, in ~/Dropbox/.stversions,
            # once they see the change. Staggered: thinner with age, gone after a year.
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
