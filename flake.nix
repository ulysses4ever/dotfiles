{
  description = "Artem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay/5e7af7d4bda485bb65a353d16a1ca38d9b73b178"; 

    # nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    # nix-doom-emacs.inputs = {
    #   nixpkgs.follows = "nixpkgs";
    #   emacs-overlay.follows = "emacs-overlay";
    # };
  };

  outputs = { home-manager, nixpkgs, ... }@inputs: { # nix-doom-emacs,

    nixosConfigurations = with builtins; let

      hosts = attrNames (readDir ./machines);

      mkHost = mname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # we only use x64, although we could make it a parameter
        modules = [
          (import (./machines + "/${mname}"))

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.artem = { pkgs, ... }: {
              imports = [ ./home.nix ]; # nix-doom-emacs.hmModule
              # programs.doom-emacs = {
              #   enable = true;
              #   doomPrivateDir = ./doom.d;
              #   emacsPackage = pkgs.emacsPgtkGcc;
              # };
            };
          }
          { 
            nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
            nixpkgs.config.allowBroken = true;
          }
        ];
        specialArgs = {
          inherit inputs;
          inherit mname;
          mypkgs = (import ./packages.nix);
        };
      };

    in nixpkgs.lib.genAttrs hosts mkHost;
  };
}
