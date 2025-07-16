{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Fix Wlan after suspend or Hibernate
  # environment.etc."systemd/system-sleep/fix-wifi.sh".source =
  #   pkgs.writeShellScript "fix-wifi.sh" ''
  #     case $1/$2 in
  #       pre/*)
  #         ${pkgs.kmod}/bin/modprobe -r mt7921e mt792x_lib mt76
  #         echo 1 > /sys/bus/pci/devices/0000:04:00.0/remove
  #         ;;

  #       post/*)
  #         ${pkgs.kmod}/bin/modprobe mt7921e
  #         echo 1 > /sys/bus/pci/rescan
  #         ;;
  #     esac
  #   '';

  boot = {
    kernelPackages = lib.mkDefault pkgs.kernel.linuxPackages;
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "cryptd" "usbhid" "sd_mod" "r8152" ];
      # allow to remote build on arm (needed for moonside)
      kernelModules = [ "sg" ];
      luks.devices."cryptroot" = {
        # improve performance on ssds
        bypassWorkqueues = true;
        preLVM = true;
        # crypttabExtraOpts = ["fido2-device=auto"];
      };
    };

    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      "mem_sleep_default=deep"
      # supposedly, this helps save power on laptops
      # in reality (at least on this model), this just generate excessive heat on the CPUs
      # "amd_pstate=passive"

      # Fix screen flickering issue at the cost of battery life (disable PSR and PSR-SU, keep PR enabled)
      # TODO: figure out if this is worth it
      # test PSR/PR state with 'sudo grep '' /sys/kernel/debug/dri/0000*/eDP-2/*_capability'
      # ref:
      # https://old.reddit.com/r/framework/comments/1goh7hc/anyone_else_get_this_screen_flickering_issue/
      # https://www.reddit.com/r/NixOS/comments/1hjruq1/graphics_corruption_on_kernel_6125_and_up/
      # https://gitlab.freedesktop.org/drm/amd/-/issues/3797
      "amdgpu.dcdebugmask=0x410"
    ];

    extraModulePackages = [ ];
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
