{
  description = "Standalone (Non-NixOS) Home Manager configuration of Artem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      mkUser = host: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./machines/${host}
          {
             nixpkgs.config.allowUnfreePredicate = (pkg: true);
          }
        ];

        # Optionally use extraSpecialArgs to pass through arguments to home.nix
        extraSpecialArgs = {
          mypkgs = (import ../packages.nix) pkgs;
        };
    };
    in {
      homeConfigurations = {
        artem = mkUser "default";
        "artem@hp-julia" = mkUser "hp-julia";
      };
    };
}
