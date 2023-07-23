{
  description = "Artem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { home-manager, nixpkgs, ... }@inputs: {

    nixosConfigurations = with builtins; let

      hosts = attrNames (readDir ./machines);

      mkHost = mname: nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux"; # we only use x64, although we could make it a parameter
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        modules = [
          (import (./machines + "/${mname}"))

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.artem = { pkgs, ... }: {
              imports = [ ./hm-only/home.nix ];
            };
          }
          { 
            nixpkgs.config.allowBroken = true;
            nixpkgs.config.allowUnfree = true;
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit mname;
          mypkgs = (import ./packages.nix) pkgs
                    ++ (import ./packages-desktop.nix) pkgs;
        };
      };

    in nixpkgs.lib.genAttrs hosts mkHost;
  };
}
