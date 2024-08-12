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
    [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./syncthing.nix
      ../../modules/standard.nix
      ../../modules/laptop.nix
    ];

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
  boot.supportedFilesystems = [ "ntfs" ];

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];


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
  # services.xserver.videoDrivers = [ "nvidia" ];
  # # --- or on certain laptops ---
  # #services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
  # #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;
  # hardware.nvidia.prime = {
  #   # sync.enable = true;
  #   offload.enable = true; # -- fancier alternative: enable per app by running:
  #   # $ nvidia-offload app

  #   # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
  #   nvidiaBusId = "PCI:45:0:0";

  #   # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
  #   intelBusId = "PCI:0:2:0";
  # };


  #######################################################################################
  #
  #   User account and interface, desktop, X server
  #

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

  # Below are dessktop-related options that are subsumed by import modules/desktop.nix above
  # environment.sessionVariables = {
  #    MOZ_ENABLE_WAYLAND = "1";
  # };

  # # X Server
  # services.xserver = {
  #   enable = true;

  #   desktopManager = {
  #     xterm.enable = false;

  #     # xfce.enable = true;

  #     gnome = {
  #       enable = true;
  #       extraGSettingsOverrides = ''
  #         [ org/gnome/desktop/peripherals/mouse ]
  #         natural-scroll=true

  #         [org.gnome.desktop.peripherals.touchpad]
  #         tap-to-click=true
  #         click-method='default'

  #         [org/gnome/shell]
  #         disable-user-extensions=false
  #         '';
  #     };

  #   };

#    windowManager.i3 = {
#      enable = false;
#      extraPackages = with pkgs; [
#        dmenu #application launcher most people use
#        i3status # gives you the default i3 status bar
#        i3lock #default i3 screen locker
#        # i3blocks #if you are planning on using i3blocks over i3status
#     ];
#    };

    # xkb.layout = "us,ru";
  # };


  #######################################################################################
  #
  #   Misc Services

  virtualisation.docker.enable = true;
  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableExtensionPack = true;

  # Northeastern loves it... Kill it asa I leave NEU...
  # services.globalprotect.enable = true;

  # Lorri -- didn't work
  # services.lorri.enable = true;

  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  #######################################################################################
  #
  #    Programs
  #

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

  #######################################################################################
  #
  #   System Packages, Paths
  #

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [
    nvidia-offload
  ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
