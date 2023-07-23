{ pkgs, ... }:

with pkgs; [

    # Gnome Desktop apps
    gnome.nautilus
    gnome.gedit
    gnome.gnome-terminal
    gnome.eog
    gnome.evince
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.file-roller
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    transmission-gtk
    baobab
    geany

    # Xfce desktop
    xfce.thunar
    xfce.thunar-volman
    # xfce.thunar-dropbox-plugin
    xfce.thunar-archive-plugin

    # styling for gtk apps
    #lxappearance # don't work on pure Wayland, instead:
    xfce.xfce4-settings # use xfce4-appearance-settings from here

    # General Desktop
    xdg-utils
    firefox-wayland brave
    zoom-us
    tdesktop
    steam
    shotwell
    libreoffice-fresh

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

    # Lighter Desktop apps
    spaceFM # file manager

    # NVIDIA+Wayland experiments
    #egl-wayland
    #xorg.libxcb
    #mesa
    #libglvnd
    #libdrm
]
