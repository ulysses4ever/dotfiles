{
  description = "Artem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { home-manager, nixpkgs, ... }@inputs: {
    nixosConfigurations.lenovo-p14s = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.artem = import ./home.nix;
          }
        ];
        specialArgs = { inherit inputs; };
      };
    };
}
