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
    zlib
    which
    pciutils
    direnv
    htop
    gnupg
    inetutils
    killall
    aumix # cli sound control
    imagemagick
    cachix

    # Temperature (and other) diagnostics
    psensor lm_sensors hddtemp

    # Modern Unix
    fd exa procs tldr bat
    silver-searcher ripgrep
    fish
    starship
    kitty
    neofetch # beautiful splash screen for terminal

    # Virtualization
    # docker

    # Gnome Desktop apps
    gnome3.nautilus
    gnome3.gedit
    gnome3.gnome-terminal
    gnome3.eog
    gnome3.evince
    #gnome3.shotwell
    gnome3.gnome-tweaks
    gnome3.dconf-editor
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    transmission-gtk
    baobab

    # Xfce desktop
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-dropbox-plugin
    xfce.thunar-archive-plugin

    # Text
    #emacs # -- using Doom Emacs through Home Manager # -- not anymore
    #emacsPgtkGcc
    libtool libvterm # emacs vterm
    emacs-all-the-icons-fonts
    geany
    texlive.combined.scheme-full pplatex
    ott
    libreoffice-fresh
    aspell
    aspellDicts.en enchant # helps with spell-checking in e.g. gEdit

    # Desktop
    xdg-utils
    firefox-wayland brave
    zoom-us
    tdesktop
    steam

    # A/V
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

    ghc cabal-install
    haskellPackages.hpack ghcid
    haskell-language-server

    coq_8_12
    (agda.withPackages (p: [p.standard-library]))

    gcc git cmake
    jdk ant maven
    python2 python3Minimal
    julia-stable-bin

    # *** Experimental ***

    # Lighter Desktop apps
    spaceFM # file manager

    # styling for gtk apps
    #lxappearance # don't work on pure Wayland, instead:
    xfce.xfce4-settings # use xfce4-appearance-settings from here

    # NVIDIA+Wayland experiments
    #egl-wayland
    #xorg.libxcb
    #mesa
    #libglvnd
    #libdrm

]
