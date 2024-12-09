{ pkgs, ... }:

{ environment.systemPackages = 
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
    imagemagick
    cachix
    comma # run soft w/o install
    findutils.locate # plocate # locate

    # Temperature (and other) diagnostics
    lm_sensors hddtemp

    # Modern Unix
    fd eza procs tldr bat
    fzf
    silver-searcher ripgrep
    fish
    starship
    kitty
    neofetch # beautiful splash screen for terminal
    tmux # the ultimate terminal manager

    # Virtualization
    docker

    # Gnome Desktop apps
    nautilus
    gedit
    gnome-terminal
    eog
    evince
    gnome-tweaks
    dconf-editor
    file-roller
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnome-keyring
    transmission_4-gtk
    baobab

    # Text
    #emacs # -- using Doom Emacs through Home Manager # -- not anymore
    #emacsPgtkGcc
    libtool libvterm # emacs vterm
    irony-server
    emacs-all-the-icons-fonts
    geany
    (texlive.combine {
        inherit (texlive)
            scheme-medium
            collection-langcyrillic
            collection-latex
            collection-latexrecommended
            collection-latexextra
            collection-fontsextra
            collection-fontutils
            collection-fontsrecommended
            collection-publishers
        ;
    })
    pplatex
    biber
    ott
    libreoffice-fresh
    aspell
    aspellDicts.en enchant # helps with spell-checking in e.g. gEdit

    # Desktop
    xdg-utils
    firefox-wayland chromium
    zoom-us
    tdesktop
    steam
    shotwell
#    bluejeans-gui

    # A/V
    pavucontrol
    ffmpeg
    vlc # don't support pure Wayland
    mpv # do support it
    #clapper # new kid on the block: supports Wayland but unpolished/buggy
    droidcam
    pamixer
    glxinfo
    obs-studio obs-studio-plugins.wlrobs
    wf-recorder v4l-utils

    # Develpoment
    binutils gnumake gdb
    nodejs # neovim wants it

    ghc cabal-install ghcid
    haskellPackages.alex
    haskellPackages.happy
    haskell-language-server

#    coq_8_12
#    (agda.withPackages (p: [p.standard-library]))

    gcc git cmake
    jdk ant maven
    python3Minimal
    julia_19

    # direnv

    # *** Experimental ***

    # Lighter Desktop apps
    # spaceFM # file manager

    # styling for gtk apps
    #lxappearance # don't work on pure Wayland, instead:
    xfce.xfce4-settings # use xfce4-appearance-settings from here

    # NVIDIA+Wayland experiments
    #egl-wayland
    #xorg.libxcb
    #mesa
    #libglvnd
    #libdrm
]; }
