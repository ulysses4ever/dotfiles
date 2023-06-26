{ pkgs, ... }:

with pkgs; [
    # Command-Line Tools
    wget mc file bc
    patchelf
    lshw
    lynx
    openvpn openssl
    parted
    sudo
    xorg.xbacklight
    zip unzip
    zlib zlib.dev
    which
    pciutils
    htop
    gnupg
    inetutils
    killall
    aumix # cli sound control
    imagemagick
    cachix
    comma # run soft w/o install
    findutils.locate # plocate # locate

    # Temperature (and other) diagnostics
    psensor lm_sensors hddtemp

    # Modern Unix
    fd exa procs tldr bat
    silver-searcher ripgrep
    fish
    starship
    kitty
    neofetch # beautiful splash screen for terminal
    tmux # the ultimate terminal manager

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
    aspell
    aspellDicts.en enchant # helps with spell-checking in e.g. gEdit

    # Develpoment
    binutils gnumake gdb
    nodejs # neovim wants it

    ghc cabal-install ghcid
    haskellPackages.hpack 
    haskellPackages.alex 
    haskellPackages.happy 
    haskellPackages.hasktags
    haskell-language-server

    coq_8_12
    (agda.withPackages (p: [p.standard-library]))

    gcc git cmake
    jdk ant maven
    python3Minimal
    julia_18-bin

    # direnv

    # direnv

]
