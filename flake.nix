{
  description = "Artem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { home-manager, nixpkgs, ... }@inputs: {

    nixosConfigurations = with builtins; let

      hosts = attrNames (readDir ./machines);

      mkHost = name: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # we only use x64, although we could make it a parameter
        modules = [
          (import (./machines + "/${name}"))

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.artem = import ./home.nix; # home-manager config is global,
                                                          # for now
          }
        ];
        specialArgs = { inherit inputs; };
      };

    in nixpkgs.lib.genAttrs hosts mkHost;
  };
}
