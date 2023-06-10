{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Haskell
    ghc cabal-install ghcid
    haskellPackages.hpack
    haskellPackages.alex
    haskellPackages.happy
    haskellPackages.hasktags
    haskell-language-server
  ];
}
