{ pkgs, ... }:

with pkgs; [
    sudo

    # Virtualization
    # docker

    # TeX
    texlive.combined.scheme-small
    pplatex
    ott

    # Develpoment
    nodejs # neovim wants it

    # Coq & Agda
    # coq_8_12
    # (agda.withPackages (p: [p.standard-library]))

    gcc cmake
    jdk ant maven
    python3Minimal
    julia-stable-bin

    # direnv

]
