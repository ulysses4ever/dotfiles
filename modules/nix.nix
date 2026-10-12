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
  };

  nix = {
    settings.trusted-users = [ "root" "artem" ];

    # The Doom Emacs build, pushed by doom-cachix-push below, so a host that
    # didn't build it downloads it instead of compiling it.
    settings.extra-substituters = [ "https://artem-dotfiles.cachix.org" ];
    settings.extra-trusted-public-keys = [
      "artem-dotfiles.cachix.org-1:Stgh8WLhtkX/3dPrFULwPp3dedCQCXDD6UP4fi24MA4="
    ];

    registry.nixpkgs.flake = inputs.nixpkgs;
    # `n` as shorthand: `nix shell n#hello`
    registry.n.to = { type = "indirect"; id = "nixpkgs"; };

    # Flakes only. With channels off, NIX_PATH is just nixpkgs=flake:nixpkgs,
    # so <nixpkgs> (nix-shell -p, as in course-status.py's shebang) is this
    # flake's nixpkgs; no channel, stale or never downloaded, comes first.
    # All Nix settings live here: no ~/.config/nix overrides them.
    channel.enable = false;

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

  # Pushes the Doom Emacs build to the artem-dotfiles cache whenever a switch
  # changes it, on a host holding a write token in /etc/cachix-doom.env
  # (CACHIX_AUTH_TOKEN=..., root-only, outside the store). Only the paths
  # cache.nixos.org lacks go up: the Doom packages and profile, ~300 paths and
  # ~360 MiB, rather than the 2 GiB closure with Emacs and GTK. A simple
  # service, so the switch doesn't wait for the upload.
  systemd.services.doom-cachix-push =
    let doom = config.home-manager.users.artem.programs.doom-emacs.finalEmacsPackage;
    in {
      description = "Push the Doom Emacs build to the artem-dotfiles Cachix cache";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartTriggers = [ doom ];
      unitConfig.ConditionPathExists = "/etc/cachix-doom.env";
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = true;
        EnvironmentFile = "/etc/cachix-doom.env";
      };
      path = with pkgs; [ bash cachix config.nix.package curl gnugrep gnused findutils ];
      script = ''
        closure=$(nix-store --query --requisites ${doom})
        missing=$(printf '%s\n' "$closure" \
          | sed -E 's|^/nix/store/([a-z0-9]{32})-.*|\1|' \
          | xargs -P 16 -I{} sh -c \
              'curl -sfI -o /dev/null https://cache.nixos.org/{}.narinfo || echo {}')
        # An empty pattern would match, and push, the whole closure.
        if [ -z "$missing" ]; then echo "nothing to push"; exit 0; fi
        printf '%s\n' "$closure" | grep -F "$missing" | cachix push artem-dotfiles
      '';
    };

}
