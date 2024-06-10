{
  description = "Artem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = github:nix-community/disko;
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { home-manager, nixpkgs, disko, ... }@inputs: {

    nixosConfigurations = with builtins; let

      hosts = attrNames (readDir ./machines);
      hostsAnywhere = attrNames (readDir ./machines-anywhere);

      mkHost = mname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # we only use x64, although we could make it a parameter
        modules = [
          (import (./machines + "/${mname}"))

          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.artem = { pkgs, ... }: {
              imports = [ ./home.nix ];
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
          mypkgs = (import ./packages.nix);
        };
      };

      mkHostAnywhere = host: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ({modulesPath, pkgs, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              disko.nixosModules.disko
              ./machines-anywhere/${host}
            ];

            # Boot
            boot.loader.grub = {
              efiSupport = true;
              efiInstallAsRemovable = true;
            };

            # Network, openssh
            networking.hostName = "${host}";
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
              };
            };

            # Users
            users.groups.artem = {};
            users.users = {
              root = {
                openssh.authorizedKeys.keys = [
                    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDipD0jpN1WxGOp+Ij5aqpLafM/6hCkf9ltaMpIlaBHxvNH2HRUbf5WOK8Vjb6lpHC0DZrsOgCc/FM96bGeIBmLZit9r1S6soAEHKIhHPjFhleBJo+T/b8F+Rm+afWMtUtVysQHe0u168g+NEovv0XzaDjBkZ+vOJUYL/u7YJbHDsLk1u+IzlIqCvelDYPrnJz49o849T3A3hfBlWx/q2WAsM8a6Wz2j+2ggzi8vo2RFQGzxswCq9KGO69XQjWgH5rw7d8I9jD2ccbj+mheVJuZLuYohTIkW8+i/93ReMvqate1LDIEpyQdm6OiyCVUn89BMmN186tNc+R5tvOaXFMT ulysses@ulysses-laptop-2"
                    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9ROUiZuXiBhaQ46UK9Oj3aOWp57q/u3grK74KIZnreP+ehLj1e03RETMlPRgmafjaE8McNJt/CNx++T0uhtT2by+FgW13pb6s97RBTcb3Y4LCQK5SoW+CrtMXNJAbag1X+2YhpA/LYhsvzbQKMQ2RnEBkR2c8ftHpBkr0V+qA+9j3IiYxcv4dek9BWLmByRmrpYdMX8tB71BNbj4dEY40PkP3A8vxRHYwe1AQ3BJU664dtJcBCRXupYrLl+OWLx3wYrpe5n1gcqnh1AVnAoL+M79Hn1+egD28TRq5yGr5C3PzZv4bJpdLiIlEzuzBbVP/hzg3C0YziaBqqBwCn9orBnS66eQq8z4MU4kGa2DwDQ/M/4VOrpSnwjmmw7C8P/qLu6nlnyqwCFul/oRXUH0rmkBV6fPxBgw6FYPsJhHMlE+4j8q/laKUTmbrGKio13xYEdFUXT1BHICMS2N7JNKo/0HXR2Frj8XsV/d3ld0xzl3Gy9BNZUbOl/xL/gkNaXM= artem@lenovo-p14s"
                    ];
                initialHashedPassword = "$6$ij6xuG830qEsJmw4$LoYxxNdKIupMp/.ZP3oEn/EPAhVmbwsUAogfd7IIXZAR4SoLO3b8N2uTQK/2D83oVwjBRZdhbgoSVH/YEKRjU/";
              };
              artem = {
                openssh.authorizedKeys.keys = [
                    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDipD0jpN1WxGOp+Ij5aqpLafM/6hCkf9ltaMpIlaBHxvNH2HRUbf5WOK8Vjb6lpHC0DZrsOgCc/FM96bGeIBmLZit9r1S6soAEHKIhHPjFhleBJo+T/b8F+Rm+afWMtUtVysQHe0u168g+NEovv0XzaDjBkZ+vOJUYL/u7YJbHDsLk1u+IzlIqCvelDYPrnJz49o849T3A3hfBlWx/q2WAsM8a6Wz2j+2ggzi8vo2RFQGzxswCq9KGO69XQjWgH5rw7d8I9jD2ccbj+mheVJuZLuYohTIkW8+i/93ReMvqate1LDIEpyQdm6OiyCVUn89BMmN186tNc+R5tvOaXFMT ulysses@ulysses-laptop-2"
                    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9ROUiZuXiBhaQ46UK9Oj3aOWp57q/u3grK74KIZnreP+ehLj1e03RETMlPRgmafjaE8McNJt/CNx++T0uhtT2by+FgW13pb6s97RBTcb3Y4LCQK5SoW+CrtMXNJAbag1X+2YhpA/LYhsvzbQKMQ2RnEBkR2c8ftHpBkr0V+qA+9j3IiYxcv4dek9BWLmByRmrpYdMX8tB71BNbj4dEY40PkP3A8vxRHYwe1AQ3BJU664dtJcBCRXupYrLl+OWLx3wYrpe5n1gcqnh1AVnAoL+M79Hn1+egD28TRq5yGr5C3PzZv4bJpdLiIlEzuzBbVP/hzg3C0YziaBqqBwCn9orBnS66eQq8z4MU4kGa2DwDQ/M/4VOrpSnwjmmw7C8P/qLu6nlnyqwCFul/oRXUH0rmkBV6fPxBgw6FYPsJhHMlE+4j8q/laKUTmbrGKio13xYEdFUXT1BHICMS2N7JNKo/0HXR2Frj8XsV/d3ld0xzl3Gy9BNZUbOl/xL/gkNaXM= artem@lenovo-p14s"
                    ];
                initialHashedPassword = "$6$ij6xuG830qEsJmw4$LoYxxNdKIupMp/.ZP3oEn/EPAhVmbwsUAogfd7IIXZAR4SoLO3b8N2uTQK/2D83oVwjBRZdhbgoSVH/YEKRjU/";
                isNormalUser = true;
                createHome = true;
                group = "artem";
                extraGroups = [ "wheel" "docker" "vboxusers" "networkmanager" ];
                shell = pkgs.fish;
              };
            };
            security.sudo.wheelNeedsPassword = false;
            programs.fish.enable = true;

            # Time zone, locale, keymap
            time.timeZone = "America/New_York";
            i18n.defaultLocale = "en_US.UTF-8";

            # Nix, nixpkgs, NixOS
            nix = {
              settings.trusted-users = [ "root" "artem" ];
              # enable flakes
              package = pkgs.nixVersions.latest;
              extraOptions = ''
                experimental-features = nix-command flakes
              '';
            };
            nixpkgs.config = {
              allowUnfree = true;
            };
            system.stateVersion = "23.11";
          }) # main module
        ];
      }; # mkHostAnywhere
    in
      nixpkgs.lib.genAttrs hostsAnywhere mkHostAnywhere
      //
      nixpkgs.lib.genAttrs hosts mkHost
      ;
  };
}
