# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  #######################################################################################
  #
  #    Boot, kernel
  #

  # Bootloader, firmware
  # https://github.com/fooblahblah/nixos/blob/master/configuration.nix
  boot.tmp.cleanOnBoot = true;
  boot.initrd.checkJournalingFS = false;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = false;
  services.fwupd.enable = true;
  powerManagement.enable = true;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  #######################################################################################
  #
  #   Misc Hardware-related
  #

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hardware.bluetooth.settings = {
	  General = {
		  Enable = "Source,Sink,Media,Socket";
	  };
  };

  # Laptop power button to suspend
  services.logind.extraConfig = "HandlePowerKey=suspend";

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;


  #######################################################################################
  #
  #   Networking
  #

  networking = {
    hostName = "nixos";

    # Either NetworkManager or wireless service -- not both! (they conflict)
    networkmanager.enable = true;
    #wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # useDHCP = false; # blanket true is not allowed anymore (they say)
    # interfaces.enp0s31f6.useDHCP = true;
    # interfaces.wlan0.useDHCP = true; # fix iwd race
    # interfaces.wlp0s20f3.useDHCP = false; # fix iwd race

    firewall.enable = false;
  };

  # Announce myself as $hostname.local in a local network and help others to do the same
  # https://github.com/NixOS/nixpkgs/issues/98050#issuecomment-1471678276
  services.resolved.enable = true; 
  networking.networkmanager.connectionConfig."connection.mdns" = 2;
  services.avahi.enable = true; 

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  #######################################################################################
  #
  #   User account and interface, desktop, X server
  #

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # Also, user-management related stuff
  users.users.artem = {
    isNormalUser = true;
    createHome = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "vboxusers" "networkmanager" "blue" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDipD0jpN1WxGOp+Ij5aqpLafM/6hCkf9ltaMpIlaBHxvNH2HRUbf5WOK8Vjb6lpHC0DZrsOgCc/FM96bGeIBmLZit9r1S6soAEHKIhHPjFhleBJo+T/b8F+Rm+afWMtUtVysQHe0u168g+NEovv0XzaDjBkZ+vOJUYL/u7YJbHDsLk1u+IzlIqCvelDYPrnJz49o849T3A3hfBlWx/q2WAsM8a6Wz2j+2ggzi8vo2RFQGzxswCq9KGO69XQjWgH5rw7d8I9jD2ccbj+mheVJuZLuYohTIkW8+i/93ReMvqate1LDIEpyQdm6OiyCVUn89BMmN186tNc+R5tvOaXFMT ulysses@ulysses-laptop-2" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Time zone, locale, keymap
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # X Server
  services.xserver = {
    enable = false;

    desktopManager = {
      xterm.enable = false;

      gnome = {
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

    };

    displayManager = {
      defaultSession = "gnome"; # "none+i3";

      autoLogin = {
        #enable = true;
        #user = "artem";
      };

      gdm = {
        enable = false;
        autoLogin.delay = 0;
      };
    };

    layout = "us,ru";

    # Enable touchpad support (enabled by default in most desktopManager).
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = false;
        tapping = true;
        middleEmulation = true;
      };
    };
  };

  # Fonts 
  fonts = { 
    enableDefaultFonts = true;
    fonts = with pkgs; [
      # main:
      fira-code
      ubuntu_font_family
      noto-fonts
      roboto
      paratype-pt-mono paratype-pt-serif paratype-pt-sans
      inconsolata hasklig # iosevka 
      liberation_ttf
      libertine
      fira-code-symbols
    ];

    fontconfig = {
      defaultFonts = {
        serif =     [ "Noto Serif Regular" ];
        sansSerif = [ "Ubuntu Regular"     ];
        monospace = [ "FiraCode Nerd Font" ];
      };
    };
  };

  #######################################################################################
  #
  #   Misc Services 
  #

  virtualisation.docker.enable = true;
  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableExtensionPack = true;

  # Lorri -- didn't work
  # services.lorri.enable = true;

  #######################################################################################
  #
  #    Programs
  #

  programs.fish.enable = true;
  
  # Nano
  programs.nano.nanorc = ''
    set nowrap
    set softwrap
    set linenumbers
    set tabsize 2
    set tabstospaces
    set autoindent
    include "${pkgs.nano}/share/nano/extra/*"
  '';

  # Neovim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    # customRC.source = builtins.readfile ./hm-only/modules/neovim.rc # when merge hm-only
    defaultEditor = true;
  };

  # Dconf
  programs.dconf.enable = true;

  # GNUPG for SSH keys management
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };


  #######################################################################################
  #
  #   System Packages 
  #

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git sudo
  ];

  #######################################################################################
  #
  #   Meta: Nix & Nixpkgs Config
  #
  nix = {
    settings.trusted-users = [ "root" "artem" ];

    # enable flakes
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;

    oraclejdk.accept_license = true;
    
    permittedInsecurePackages = [
      "libplist-1.12"
      "libgit2-0.27.10"
    ];
    
    packageOverrides = pkgs: rec {
      unstable = import <unstable> {
        # pass the nixpkgs config to the unstable alias
        # to ensure `allowUnfree = true;` is propagated:
        config = config.nixpkgs.config;
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
