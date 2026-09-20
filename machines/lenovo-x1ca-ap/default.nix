{ config, pkgs, lib, inputs, mname, ... }:

let
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDipD0jpN1WxGOp+Ij5aqpLafM/6hCkf9ltaMpIlaBHxvNH2HRUbf5WOK8Vjb6lpHC0DZrsOgCc/FM96bGeIBmLZit9r1S6soAEHKIhHPjFhleBJo+T/b8F+Rm+afWMtUtVysQHe0u168g+NEovv0XzaDjBkZ+vOJUYL/u7YJbHDsLk1u+IzlIqCvelDYPrnJz49o849T3A3hfBlWx/q2WAsM8a6Wz2j+2ggzi8vo2RFQGzxswCq9KGO69XQjWgH5rw7d8I9jD2ccbj+mheVJuZLuYohTIkW8+i/93ReMvqate1LDIEpyQdm6OiyCVUn89BMmN186tNc+R5tvOaXFMT ulysses@ulysses-laptop-2"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9ROUiZuXiBhaQ46UK9Oj3aOWp57q/u3grK74KIZnreP+ehLj1e03RETMlPRgmafjaE8McNJt/CNx++T0uhtT2by+FgW13pb6s97RBTcb3Y4LCQK5SoW+CrtMXNJAbag1X+2YhpA/LYhsvzbQKMQ2RnEBkR2c8ftHpBkr0V+qA+9j3IiYxcv4dek9BWLmByRmrpYdMX8tB71BNbj4dEY40PkP3A8vxRHYwe1AQ3BJU664dtJcBCRXupYrLl+OWLx3wYrpe5n1gcqnh1AVnAoL+M79Hn1+egD28TRq5yGr5C3PzZv4bJpdLiIlEzuzBbVP/hzg3C0YziaBqqBwCn9orBnS66eQq8z4MU4kGa2DwDQ/M/4VOrpSnwjmmw7C8P/qLu6nlnyqwCFul/oRXUH0rmkBV6fPxBgw6FYPsJhHMlE+4j8q/laKUTmbrGKio13xYEdFUXT1BHICMS2N7JNKo/0HXR2Frj8XsV/d3ld0xzl3Gy9BNZUbOl/xL/gkNaXM= artem@lenovo-p14s"
  ];
in
{

  #######################################################################################
  #
  #   Imports
  #

  imports =
    [
      ./hardware-configuration.nix
      ./syncthing.nix
      ../../modules/standard.nix
      ../../modules/laptop.nix
      ../../modules/docker.nix
    ];

  # pkgsUnstable comes from modules/nix.nix, which standard.nix pulls in.

  #######################################################################################
  #
  #   Boot, firmware
  #

  # /boot is the 450M factory ESP shared with Windows, leaving ~408M. A
  # generation measures ~54M of kernel+initrd, so this has to stay capped well
  # under eight or activation fails on a full ESP.
  boot.loader.systemd-boot.configurationLimit = 3;

  boot.tmp.cleanOnBoot = true;
  boot.initrd.checkJournalingFS = false;
  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;
  powerManagement.enable = true;

  #######################################################################################
  #
  #   Credentials
  #
  #   users/artem.nix sets no password and no keys, which is fine for the hosts
  #   that were installed by hand and had `passwd` run on the console. This one
  #   was installed remotely with no console step, so without these the first
  #   boot would be unreachable.

  users.users.artem = {
    openssh.authorizedKeys.keys = sshKeys;
    initialHashedPassword = "$6$ij6xuG830qEsJmw4$LoYxxNdKIupMp/.ZP3oEn/EPAhVmbwsUAogfd7IIXZAR4SoLO3b8N2uTQK/2D83oVwjBRZdhbgoSVH/YEKRjU/";
  };
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  #######################################################################################
  #
  #   Desktop
  #

  environment.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ] ; then
        export QT_QPA_PLATFORM=wayland
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_WEBRENDER=1
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
        export XCURSOR_THEME='Adwaita'
        export XCURSOR_SIZE=26
        exec sway
    fi
  '';

  #######################################################################################
  #
  #   Services, programs
  #

  services.tailscale.enable = true;

  networking.networkmanager.plugins = with pkgs; [ networkmanager-openconnect ];

  # modules/network.nix pins wlan0 and eno1; this machine has wlp0s20f3 and no
  # builtin ethernet. NetworkManager covers DHCP, and letting avahi bind every
  # interface is what makes lenovo-x1ca-ap.local resolve.
  networking.interfaces = lib.mkForce { };
  services.avahi.allowInterfaces = lib.mkForce null;

  environment.variables.EDITOR = "vim";

  system.stateVersion = "26.05";

}
