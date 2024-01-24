# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, mname, mypkgs, ... }:


let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
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
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

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

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Brightness via Fn keys
  services.illum.enable = true;

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;


  #######################################################################################
  #
  #   Networking
  #

  networking = {
    hostName = "${mname}"; # Define your hostname.

    # Either NetworkManager or wireless service -- not both! (they conflict)
    networkmanager.enable = true;
    #wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    #networkmanager.wifi.backend = "iwd";
    #wireless.iwd.settings.General.UseDefaultInterface = true;

    useDHCP = false; # blanket true is not allowed anymore (they say)
    interfaces.enp0s31f6.useDHCP = true;
    interfaces.wlan0.useDHCP = true; # fix iwd race
    #interfaces.wlp0s20f3.useDHCP = false; # fix iwd race
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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  #######################################################################################
  #
  #   Graphics
  #

  # OpenGL
  hardware.opengl.enable = true;
  # Needed by Steam (or so I heard)
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;

  # Wayland with Nvidia drivers is complicated
  #services.xserver.displayManager.gdm.wayland = false; # true didn't make any difference to me
  # services.xserver.displayManager.gdm.nvidiaWayland = true;
  #hardware.nvidia.modesetting.enable = true; # ?
  #hardware.nvidia.nvidiaPersistenced = true; # ?

  # NVIDIA card drivers onfig
  services.xserver.videoDrivers = [ "nvidia" ];
  # --- or on certain laptops ---
  #services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;
  hardware.nvidia.prime = {
    # sync.enable = true;
    offload.enable = true; # -- fancier alternative: enable per app by running:
    # $ nvidia-offload app

    # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
    nvidiaBusId = "PCI:45:0:0";

    # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
    intelBusId = "PCI:0:2:0";
  };

  # Hopefully helps to screen-share under Wayland
  services.pipewire.enable = true;
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
  };
  security.sudo.wheelNeedsPassword = false;

  # Time zone, locale, keymap
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Sway: env vars
  # TODO: Should be done in a more flexible way (e.g. Sway options in home-manager)
  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] ; then
        # Your environment variables
        export QT_QPA_PLATFORM=wayland
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_WEBRENDER=1
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
        export XCURSOR_THEME='Adwaita'
        export XCURSOR_SIZE=26
        exec sway --unsupported-gpu
    fi
  '';
  environment.sessionVariables = {
     MOZ_ENABLE_WAYLAND = "1";
  };

  # X Server
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;

      # xfce.enable = true;
        
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

      lightdm = {
        enable = false;
        #autoLogin.timeout = 0;
        #greeter.enable = false; # uncomment if autologin is on
      };
      sddm = {
        enable = true;
        #autoLogin.delay = 0;
      };
      gdm = {
        enable = false;
        #autoLogin.delay = 0;
      };
    };

#    windowManager.i3 = {
#      enable = false;
#      extraPackages = with pkgs; [
#        dmenu #application launcher most people use
#        i3status # gives you the default i3 status bar
#        i3lock #default i3 screen locker
#        # i3blocks #if you are planning on using i3blocks over i3status
#     ];
#    };

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

  #######################################################################################
  #
  #   Misc Services 
  #

  virtualisation.docker.enable = true;
  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableExtensionPack = true;

  # Northeastern loves it... Kill it asa I leave NEU...
  services.globalprotect.enable = true;

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

  # the one true editor
  environment.variables.EDITOR = "vim";

  # Neovim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  
  # Sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ 
      swaylock swayidle xwayland
      swaykbdd
      bemenu dmenu-wayland wofi # launchers: which one is bettter?
      brillo # control brightness
      theme-sh # control color scheme in foot
      waybar
      grim slurp
      wlsunset
      wl-clipboard
      mako # notification daemon
      wdisplays # monitor manager
      xdg-desktop-portal-wlr # screen sharing engine
    ];
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
    pinentryFlavor = "gnome3";
  };


  #######################################################################################
  #
  #   System Packages, Paths
  #

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = mypkgs pkgs ++ [
    nvidia-offload
  ];

  environment.gnome.excludePackages = with pkgs.gnome3; [
  ];

  environment.localBinInPath = true;

  #######################################################################################
  #
  #   Meta: Nix & Nixpkgs Config
  #
  nix = {
    settings.trusted-users = [ "root" "artem" ];

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    registry.nixpkgs.flake = inputs.nixpkgs;

    # enable flakes
    package = pkgs.nixUnstable;
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
