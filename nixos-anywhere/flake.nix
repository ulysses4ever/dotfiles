# ❯ nix run github:numtide/nixos-anywhere -- --flake .#<host> root@host-IP
{
  inputs.nixpkgs.url = github:NixOS/nixpkgs;
  inputs.disko.url = github:nix-community/disko;
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  outputs = { self, nixpkgs, disko, ... }@attrs: {
    #-----------------------------------------------------------
    # The following line names the configuration as hetzner-cloud
    # This name will be referenced when nixos-remote is run
    #-----------------------------------------------------------
    nixosConfigurations = with builtins; let
      hosts = attrNames (readDir ./machines);

      mkHost = host: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ({modulesPath, pkgs, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              disko.nixosModules.disko
              ./machines/${host}
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
            #-------------------------------------------------------
            # Change the lines below replacing with your own ssh public key and hashed password
            #-------------------------------------------------------
            users.users.root = {
              openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDipD0jpN1WxGOp+Ij5aqpLafM/6hCkf9ltaMpIlaBHxvNH2HRUbf5WOK8Vjb6lpHC0DZrsOgCc/FM96bGeIBmLZit9r1S6soAEHKIhHPjFhleBJo+T/b8F+Rm+afWMtUtVysQHe0u168g+NEovv0XzaDjBkZ+vOJUYL/u7YJbHDsLk1u+IzlIqCvelDYPrnJz49o849T3A3hfBlWx/q2WAsM8a6Wz2j+2ggzi8vo2RFQGzxswCq9KGO69XQjWgH5rw7d8I9jD2ccbj+mheVJuZLuYohTIkW8+i/93ReMvqate1LDIEpyQdm6OiyCVUn89BMmN186tNc+R5tvOaXFMT ulysses@ulysses-laptop-2" ];
              initialHashedPassword = "$6$ij6xuG830qEsJmw4$LoYxxNdKIupMp/.ZP3oEn/EPAhVmbwsUAogfd7IIXZAR4SoLO3b8N2uTQK/2D83oVwjBRZdhbgoSVH/YEKRjU/";
            };

            # Time zone, locale, keymap
            time.timeZone = "America/New_York";
            i18n.defaultLocale = "en_US.UTF-8";

            # Nix, nixpkgs
            nix = {
              settings.trusted-users = [ "root" ];
              # enable flakes
              package = pkgs.nixUnstable;
              extraOptions = ''
                experimental-features = nix-command flakes
              '';
            };
            nixpkgs.config = {
              allowUnfree = true;
            };
          }) # main module
        ];
      }; # mkHost
      in nixpkgs.lib.genAttrs hosts mkHost;
  }; # outputs
}
