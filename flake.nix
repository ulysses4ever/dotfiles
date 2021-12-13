{
  description = "Artem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    emacs-overlay.url = "github:nix-community/emacs-overlay/5e7af7d4bda485bb65a353d16a1ca38d9b73b178"; #ac5385f1b6304137f104fc409b5aa17f5def67c7

    # doom-emacs.url = "github:hlissner/doom-emacs"; #0869d28483b5d81b818b110af351fd5c4dc04dd9
    # doom-emacs.flake = false;
    # nix-doom-emacs.url = "github:he-la/nix-doom-emacs/e74b5547aac7ce60de312b6433114614e52c692c";
    # nix-doom-emacs.inputs.doom-emacs.follows = "doom-emacs";
    # nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    # nix-doom-emacs.inputs.emacs-overlay.follows = "emacs-overlay";
  };

  outputs = { home-manager, nixpkgs, ... }@inputs: { # nix-doom-emacs, 

    nixosConfigurations = with builtins; let

      hosts = attrNames (readDir ./machines);

      mkHost = name: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # we only use x64, although we could make it a parameter
        modules = [
          (import (./machines + "/${name}"))

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.artem = { pkgs, ... }: {
              imports = [ ./home.nix ]; # nix-doom-emacs.hmModule
              # programs.doom-emacs = {
              #   enable = true;
              #   doomPrivateDir = ./doom.d;
              #   emacsPackage = pkgs.emacsPgtk;
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
          inherit name;
          mypkgs = (import ./packages.nix);
        };
      };

    in nixpkgs.lib.genAttrs hosts mkHost;
  };
}
