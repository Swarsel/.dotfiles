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

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    self.modules.nixos.disk-setup
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
    rootMirrorDisk = "/dev/disk/by-id/ata-C300-CTFDDAC064MAG_00000000104302FE494D";
    writeGlobalNetworks = false;
  };

  topology.self.interfaces.lan = { };

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  hardware.enableRedistributableFirmware = true;
}
