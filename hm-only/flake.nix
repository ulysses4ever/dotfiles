# build it with
# ❯ nix run ~/dotfiles/hm-only#hm -- switch --flake ~/dotfiles/hm-only
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
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkUser = host: user:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home.nix
            ./machines/${host}
            {
              nixpkgs.config.allowUnfreePredicate = (pkg: true);
            }
          ];

          # Optionally use extraSpecialArgs to pass through arguments to home.nix
          extraSpecialArgs = {
            inherit host;
            inherit user;
          };
      };
    in {
      homeConfigurations = {
        artem = mkUser "default" "artem";
        julia = mkUser "default" "julia";
        "artem@hp-julia" = mkUser "hp-julia" "artem";
        "artem@prl-julia" = mkUser "prl-julia" "artem";
      };
      packages.${system}.hm = home-manager.packages.${system}.default;
    };
}
