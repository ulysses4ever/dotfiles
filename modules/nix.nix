{ config, lib, pkgs, inputs, ... }:

{
  #######################################################################################
  #
  #   Meta: Nix & Nixpkgs Config
  #
  nixpkgs.config = {
    allowUnfree = true;

    oraclejdk.accept_license = true;

    packageOverrides = pkgs: rec {
      unstable = import <unstable> {
        # pass the nixpkgs config to the unstable alias
        # to ensure `allowUnfree = true;` is propagated:
        config = config.nixpkgs.config;
      };
    };
  };

  nix = {
    settings.trusted-users = [ "root" "artem" ];

    registry.nixpkgs.flake = inputs.nixpkgs;

    # enable flakes
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

}
