{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    binfmt.emulatedSystems = [
      "x86_64-linux"
      "i686-linux"
    ];
    extraModulePackages = [ ];
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
  };

  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
}
