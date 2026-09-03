# ThinkPad X1 Carbon Gen 13 (21NS005SUS), Core Ultra 7 268V, 32G, Samsung 512G NVMe.
# Written by hand rather than by nixos-generate-config: the NixOS partitions are
# added alongside a factory Windows install, so the devices below are pinned to
# partition labels created for p5/p6 and to the pre-existing Windows ESP, which
# must never be reformatted.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-partlabel/nixos-root";
      fsType = "ext4";
    };

  # Shared with Windows. Reformatting this destroys the Windows Boot Manager.
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/361C-CAAF";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-partlabel/nixos-swap"; }
    ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
