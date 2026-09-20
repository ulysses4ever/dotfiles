{ config, lib, pkgs, inputs, ... }:

{
  #######################################################################################
  #
  #   Meta: Nix & Nixpkgs Config
  #

  # Lets any module take `pkgsUnstable` as an argument and pull single packages
  # from unstable. Defined here, which every machine reaches, rather than in
  # each machine: toshiba-portege-z930 skips standard.nix and so would have been
  # the one host where a shared list like packages.nix could not use it.
  _module.args.pkgsUnstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (config.nixpkgs) config;
  };

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

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    optimise.automatic = true;

    # enable flakes
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

}
