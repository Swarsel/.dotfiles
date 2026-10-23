{
  self,
  inputs,
  lib,
  minimal,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    self.modules.nixos.systemd-networkd-server-home
    self.modules.nixos.nix-topology-self
  ]
  ++ lib.optionals minimal [
    self.modules.nixos.server-network
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.smartctl-exporter
  ];

  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "ASRock J4105-ITX, 32GB RAM";
    initrdVLAN = "home";
    isBtrfs = true;
    isCrypted = true;
    isImpermanence = true;
    isLinux = true;
    isSecureBoot = true;
    isSwap = false;
    localVLANs = [
      "services"
      "home"
      "iot"
    ];
    networkKernelModules = [ "r8169" ];
    proxyHost = "twothreetunnel";
    rootDisk = "/dev/disk/by-id/ata-Vi550_S3_SSD_493525388374974";
    writeGlobalNetworks = false;
  };

  topology.self.interfaces.lan = { };

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  hardware.enableRedistributableFirmware = true;
}
