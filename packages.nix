{ pkgs, ... }:

with pkgs; [
    sudo

    # Virtualization
    # docker

    # Text
    #emacs # -- using Doom Emacs through Home Manager # -- not anymore
    #emacsPgtkGcc
    libtool libvterm # emacs vterm
    emacs-all-the-icons-fonts
    geany
    (texlive.combine {
      inherit (texlive) scheme-small algorithms cm-super;
    })
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
    julia_18-bin

    # direnv
]
