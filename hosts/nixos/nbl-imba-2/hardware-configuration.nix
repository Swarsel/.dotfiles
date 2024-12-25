{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "cryptd" "usbhid" "sd_mod" "r8152" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];

  # Fix screen flickering issue at the cost of battery life (disable PSR and PSR-SU, keep PR enabled)
  # TODO: figure out if this is worth it
  # test PSR/PR state with 'sudo grep '' /sys/kernel/debug/dri/0000*/eDP-2/*_capability'
  # ref:
  # https://old.reddit.com/r/framework/comments/1goh7hc/anyone_else_get_this_screen_flickering_issue/
  # https://www.reddit.com/r/NixOS/comments/1hjruq1/graphics_corruption_on_kernel_6125_and_up/
  # https://gitlab.freedesktop.org/drm/amd/-/issues/3797
  boot.kernelParams = [ "amdgpu.dcdebugmask=0x410" ];

  boot.extraModulePackages = [ ];
  boot.initrd.luks.devices."cryptroot" = {
    # improve performance on ssds
    bypassWorkqueues = true;
    preLVM = true;
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp196s0f3u1c2.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
