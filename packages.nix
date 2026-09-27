{ pkgs, pkgsUnstable, ... }:

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
    xbacklight
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
    tmux # the ultimate terminal manager
    jq # deal with JSON like a pro
    mermaid-cli # diagrams from text

    # Gnome Desktop apps
     nautilus
     gedit
     gnome-terminal
     eog
     papers # PDF viewer; GNOME's rename of evince
     gnome-tweaks
     dconf-editor
     file-roller
     gnomeExtensions.appindicator
     gnomeExtensions.dash-to-dock
     gnome-keyring
     transmission_4-gtk
     baobab

     # Text

     libtool libvterm # emacs vterm
     irony-server
     emacs-all-the-icons-fonts
     copilot-language-server
     multimarkdown

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
    firefox chromium
    # From unstable: 26.05's zoom-us leaves libxcb-util out of the FHS sandbox,
    # so /opt/zoom/zopen, the bare Qt helper that hands the SSO login URL to the
    # browser, dies loading the xcb platform plugin and the SSO "Continue"
    # button does nothing. (The main client only survives because it links
    # xcb-image/cursor/keysyms directly and their runpaths drag xcb-util in.)
    # Unstable fixed the dependency list along with 7.1.5. The price is a
    # second dependency tree: 2.8 GiB unique in the store, 1.7 GiB net of what
    # stable's zoom held (measured 2026-09). If that is too dear on a small /,
    # the lean fix on stable is
    # `zoom-us.override { targetPkgsFixed = [ libxcb-util ]; }`.
    pkgsUnstable.zoom-us
    telegram-desktop
    shotwell

     # A/V
     pavucontrol
     ffmpeg
     vlc # don't support pure Wayland
     mpv # do support it
     #clapper # new kid on the block: supports Wayland but unpolished/buggy
     droidcam
     pamixer
     mesa-demos
     # obs-studio obs-studio-plugins.wlrobs
     wf-recorder v4l-utils

    # Develpoment
    binutils gnumake gdb
    nodejs # neovim wants it
    gh
    pkgsUnstable.claude-code # released far faster than a NixOS cycle

    ghc cabal-install ghcid
    haskellPackages.alex
    haskellPackages.happy
    # haskellPackages.hasktags # (used by Emacs)
    haskell-language-server

 #    coq_8_12
 #    (agda.withPackages (p: [p.standard-library]))

     gcc git cmake
     jdk ant maven
     # A full python with the two modules ~/edu/scripts needs, so every script
     # there runs as `./x.py` or `python3 x.py` with no nix-shell around it.
     # python3Minimal, which was here until 2026-09-27, has no ssl, no zlib and
     # no third-party modules: brightspace.py could not reach https, its tests
     # could not read Firefox's session store, and each script had to relaunch
     # itself under nix-shell to run at all. lz4 is Firefox's session-store
     # container; pyyaml reads course-status.yml.
     (python3.withPackages (ps: with ps; [ lz4 pyyaml ]))
     julia-lts
     (callPackage ./pkgs/pyret { })

     # direnv

     # *** Experimental ***

     # Lighter Desktop apps
     # spaceFM # file manager

    # styling for gtk apps
    #lxappearance # don't work on pure Wayland, instead:
    xfce4-settings # use xfce4-appearance-settings from here

     # NVIDIA+Wayland experiments
     #egl-wayland
     #xorg.libxcb
     #mesa
     #libglvnd
     #libdrm
]; }
