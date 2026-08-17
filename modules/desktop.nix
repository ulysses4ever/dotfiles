{ config, lib, pkgs, ... }:

{

  hardware.graphics.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us,ru";
      variant = "";
    };
  };
    # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome  = {
    enable = true;
    extraGSettingsOverrides = ''
      [ org/gnome/desktop/peripherals/mouse ]
      natural-scroll=true

      [org.gnome.desktop.peripherals.touchpad]
      tap-to-click=true
      click-method='default'

      [org/gnome/shell]
      disable-user-extensions=false
      '';
    };
  programs.dconf.enable = true; # many gnome programs need this
  services.gvfs.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Sway window manager (https://nixos.wiki/wiki/Sway)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  services.gnome.gnome-keyring.enable = true;
  environment.systemPackages = with pkgs; [
    # sway
    grim slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    mako # notification system developed by swaywm maintainer
    waybar
    wlsunset
    theme-sh
    brillo
    bemenu dmenu-wayland wofi
    swaylock swaykbdd swayidle
    wdisplays
    adwaita-icon-theme
  ];
  # Hopefully helps to screen-share under Wayland
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        #xdg-desktop-portal-gtk
      ];
      #gtkUsePortal = true;
    };
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # Something in the desktop stack pulls in pinentry-gnome3, which pops a
    # dialog on DISPLAY :0 — invisible to a terminal or ssh session, so signing
    # there just hangs until it times out. Curses prompts in the tty instead.
    pinentryPackage = pkgs.pinentry-curses;
    # The agent is per-login-session, not per-terminal, so one unlock covers
    # every shell until these expire. Defaults are 600s idle / 7200s absolute,
    # which means re-typing the passphrase several times a day just to commit.
    settings = {
      default-cache-ttl = 604800;
      max-cache-ttl = 604800;
    };
  };

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # main:
      nerd-fonts.fira-code
      nerd-fonts.ubuntu
      fira-code
      ubuntu-classic
      noto-fonts
      roboto roboto-mono
      symbola # Doom Emacs recommends

      # misc:
      corefonts
      libre-franklin
      paratype-pt-mono paratype-pt-serif paratype-pt-sans
      inconsolata hasklig # iosevka
      noto-fonts-color-emoji
      liberation_ttf
      libertine
      fira-code-symbols
      #mplus-outline-fonts
      pkgs.emacs-all-the-icons-fonts
    ];

    fontconfig = {
      defaultFonts = {
        serif =     [ "Noto Serif Regular" ];
        sansSerif = [ "Ubuntu Regular"     ];
        monospace = [ "FiraCode Nerd Font" ];
      };
    };
  };

}
