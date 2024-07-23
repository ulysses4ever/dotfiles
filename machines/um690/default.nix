# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../packages.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "um690"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Indiana/Indianapolis";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.artem = {
    isNormalUser = true;
    description = "Artem Pelenitsyn";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    #  thunderbird
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git

    # sway
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    mako # notification system developed by swaywm maintainer
    waybar
    wlsunset
    theme-sh
    brillo
    bemenu dmenu-wayland wofi
    swaylock swaykbdd
    wdisplays
    xdg-desktop-portal-wlr # screen sharing engine
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # enable sway window manager (https://nixos.wiki/wiki/Sway)
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  services.gnome.gnome-keyring.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services = {
    syncthing = {
      enable = true;
      user = "artem";
      overrideDevices = true;
      overrideFolders = true;
      configDir = "/home/artem/.config/syncthing";
      settings = {
        devices = {
          "netcup" = { id = "U25H2L7-KJY7IXJ-HHD2D76-4LBMTBZ-2CJE2NM-DBZO2V7-IUVFGPI-JGBXRQA"; };
          "pixel7a" = { id = "B2UK2TS-WJQ224N-MZ6UUSL-AHRZ6Z5-VMJWTFV-KZGWIJD-T66PZAS-OFPHUA2"; };
        };
        folders = {
          "Dropbox" = {
            path = "/home/artem/Dropbox";
            devices = [ "netcup" "pixel7a" ];
          };
          "Pixel7a-Pictures" = {
            id = "pixel_7a_j24u-photos";
            path = "/home/artem/Pictures/Cell/pixel7a";
            devices = [ "pixel7a" ];
          };
        };
      };
    };
  };

  # Photoprism will use Mysql and maybe Nginx
  # fileSystems."/var/lib/private/photoprism/originals" =
  #   { device = "/data/originals";
  #     options = [ "bind" ];
  #   };
  # services.photoprism = {
  #   enable = true;
  #   port = 2342;
  #   # originalsPath = "/home/artem/Pictures/Photoprism";
  #   originalsPath = "/var/lib/private/photoprism/originals";
  #   address = "0.0.0.0";
  #   settings = {
  #     PHOTOPRISM_ADMIN_USER = "admin";
  #     PHOTOPRISM_ADMIN_PASSWORD = "123456";
  #     PHOTOPRISM_DEFAULT_LOCALE = "en";
  #     PHOTOPRISM_DATABASE_DRIVER = "mysql";
  #     PHOTOPRISM_DATABASE_NAME = "photoprism";
  #     PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";
  #     PHOTOPRISM_DATABASE_USER = "photoprism";
  #     PHOTOPRISM_SITE_URL = "http://127.0.0.1:2342";
  #     PHOTOPRISM_SITE_TITLE = "My PhotoPrism";
  #   };
  # };

  # # MySQL
  # services.mysql = {
  #   enable = true;
  #   package = pkgs.mariadb;
  #   ensureDatabases = [ "photoprism" ];
  #   ensureUsers = [ {
  #     name = "photoprism";
  #     ensurePermissions = {
  #       "photoprism.*" = "ALL PRIVILEGES";
  #     };
  #   } ];
  # };

  # NGINX
  # services.nginx = {
  #   enable = true;
  #   # recommendedTlsSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedGzipSettings = true;
  #   recommendedProxySettings = true;
  #   clientMaxBodySize = "500m";
  #   virtualHosts = {
  #     # "pp.um690.local" = {
  #     #   # forceSSL = true;
  #     #   # enableACME = true;
  #     #   http2 = true;
  #     #   locations."/" = {
  #     #     proxyPass = "http://127.0.0.1:2342";
  #     #     proxyWebsockets = true;
  #     #     extraConfig = ''
  #     #       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #     #       proxy_set_header Host $host;
  #     #       proxy_buffering off;
  #     #     '';
  #     #   };
  #     # };
  #     "localhost" = {
  #       root = "/var/pics";
  #     };
  #   };
  # };
  services.httpd = {
    enable = true;
    virtualHosts."localhost".enableUserDir = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Announce myself as $hostname.local in a local network and help others to do the same
  # https://github.com/NixOS/nixpkgs/issues/98050#issuecomment-1471678276
  services.resolved.enable = true;
  networking.networkmanager.connectionConfig."connection.mdns" = 2;
  services.avahi.enable = true;

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # main:
      (nerdfonts.override { fonts = [ "FiraCode" "Ubuntu" ]; })
      fira-code
      ubuntu_font_family
      noto-fonts
      roboto roboto-mono

      # misc:
      paratype-pt-mono paratype-pt-serif paratype-pt-sans
      inconsolata hasklig # iosevka
      noto-fonts-emoji
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

  nix = {
    settings.trusted-users = [ "root" "artem" ];

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    registry.nixpkgs.flake = inputs.nixpkgs;

    # enable flakes
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
