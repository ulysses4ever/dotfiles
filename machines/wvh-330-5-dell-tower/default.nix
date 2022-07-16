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
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # [1]: https://github.com/fooblahblah/nixos/blob/master/configuration.nix
  boot.cleanTmpDir = true;
  boot.initrd.checkJournalingFS = false;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = false;
  services.fwupd.enable = true;
  powerManagement.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  hardware.bluetooth.settings = {
	  General = {
		  Enable = "Source,Sink,Media,Socket";
	  };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  boot.supportedFilesystems = [ "ntfs" ];

  networking = {
    hostName = "${mname}"; # Define your hostname.

    # Either NetworkManager or wireless service -- not both! (they conflict)
    networkmanager.enable = true;
    #networkmanager.umanaged = [ "eno1" ];
    #wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    #networkmanager.wifi.backend = "iwd";
    #wireless.iwd.settings.General.UseDefaultInterface = true;

    useDHCP = false; # blanket true is not allowed anymore (they say)
    interfaces.eno1.useDHCP = true;
    #interfaces.wlp0s20f3.useDHCP = false; # fix iwd race
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Login and Desktop Management
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
  services = {
    xserver = {
      enable = false;

      desktopManager = {
        xterm.enable = false;
      };

      displayManager = {
        defaultSession = "xfce"; # "none+i3";

        autoLogin = {
          #enable = true;
          #user = "artem";
        };

        lightdm = {
          enable = false;
          #autoLogin.timeout = 0;
          #greeter.enable = false; # uncomment if autologin is on
        };
        gdm = {
          enable = false;
          autoLogin.delay = 0;
        };
      };

      windowManager.i3 = {
        enable = false;
        extraPackages = with pkgs; [
          dmenu #application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          # i3blocks #if you are planning on using i3blocks over i3status
       ];
      };

      desktopManager.xfce.enable = true;
        
      desktopManager.gnome = {
        enable = false;
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
  };

  # Wayland with Nvidia drivers is complicated
  #services.xserver.displayManager.gdm.wayland = false; # true didn't make any difference to me
  # services.xserver.displayManager.gdm.nvidiaWayland = true;
  #hardware.nvidia.modesetting.enable = true; # ?
  #hardware.nvidia.nvidiaPersistenced = true; # ?

  # NVIDIA Config
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

  # Configure keymap in X11
  services.xserver.layout = "us,ru";

  # Laptop power button to suspend
  services.logind.extraConfig = "HandlePowerKey=suspend";

  # Enable CUPS to print documents
  #services.printing.enable = true;
  # due to a BUG soon to be fixed

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  
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
  environment.sessionVariables = {
     MOZ_ENABLE_WAYLAND = "1";
  };

  hardware.opengl.enable = true;
  # Needed by Steam (or so I heard)
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.pulseaudio.support32Bit = true;

  # Enable touchpad support (enabled by default in most desktopManager).
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      tapping = true;
      middleEmulation = true;
    };
  };

  services.globalprotect.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.artem = {
    isNormalUser = true;
    createHome = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "vboxusers" "networkmanager" "blue" ];
  };

  ############
  #
  # Programs
  #

  # Lorri -- didn't work
  # services.lorri.enable = true;
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
  # fails: https://github.com/NixOS/nixpkgs/issues/132389
  # fix submitted: https://nixpk.gs/pr-tracker.html?pr=132522
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


  ############
  #
  # Packages 
  #

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = mypkgs pkgs ++ [
    nvidia-offload
  ];

  environment.gnome.excludePackages = with pkgs.gnome3; [
  ];

    ############
  #
  # Fonts 
  #

  fonts = { 
    enableDefaultFonts = true;
    fonts = with pkgs; [
      # main:
      (nerdfonts.override { fonts = [ "FiraCode" "Ubuntu" ]; })
      fira-code
      ubuntu_font_family
      noto-fonts
      roboto

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
  
  # all-hail Emacs overlays!
  nixpkgs.overlays = [
    (import inputs.emacs-overlay)
  ];

  security.sudo.wheelNeedsPassword = false;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  #virtualisation.docker.enable = true;
  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableExtensionPack = true;
   
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
