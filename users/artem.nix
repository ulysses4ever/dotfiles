{ config, lib, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.artem = {
    isNormalUser = true;
    description = "Artem Pelenitsyn";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "vboxusers" "networkmanager" "blue" ];
  };
}
