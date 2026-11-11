{
  self,
  inputs,
  config,
  lib,
  confLib,
  minimal,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    self.modules.nixos.disk-mirrored-root
    self.modules.nixos.systemd-networkd-server-home
    self.modules.nixos.microvm-host
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.wireguard
    self.modules.nixos.restic
    self.modules.nixos.syncoid
    self.modules.nixos.podman
    self.modules.nixos.opkssh
    self.modules.nixos.smartctl-exporter
    self.modules.nixos.zfs-exporter
    self.modules.nixos.ipmi-exporter
  ];
  swarselsystems = {
    flakePath = "/root/.dotfiles";
    info = "ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM";
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
    ]; # devices is only provided on interface for bmc
    microVMPool = "Speed";
    networkKernelModules = [ "igb" ];
    proxyHost = "twothreetunnel";
    rootDisk = "/dev/disk/by-id/ata-TS120GMTS420S_J024880123";
    rootMirrorDisk = "/dev/disk/by-id/ata-Intenso_SSD_Sata_III_2026071600222";
    server = {
      restic.targets = {
        SwarselState = {
          # nextcloud stores all data in state dir and has no data that needs backup
          paths = lib.map (guest: "/${config.swarselsystems.microVMPool}/guests/${guest}/state") (
            builtins.filter (name: name != "nextcloud") (builtins.attrNames config.guests)
          );
          repository = config.repo.secrets.local.resticRepoState;
        };
        SwarselStorage = {
          paths = [
            "/${config.swarselsystems.storagePool}/Eternor/Pictures"
            "/${config.swarselsystems.storagePool}/Eternor/Documents/paperless"
          ];
          repository = config.repo.secrets.local.resticRepoStorage;
        };
      };
      sanoid.datasets."${config.swarselsystems.microVMPool}/guests" = { };
      syncoid.targets."${config.swarselsystems.microVMPool}/guests".target =
        "${config.swarselsystems.storagePool}/backup/guests";
    };
    storagePool = "Lazy";
    withMicroVMs = true;
    writeGlobalNetworks = false;
  };
  topology.self.interfaces = {
    bmc = { };
    lan = { };
  };
  boot = {
    blacklistedKernelModules = [
      "snd_virtuoso"
      "snd_oxygen"
    ];
    initrd.kernelModules = [
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio"
    ];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "vfio-pci.ids=13f6:8788"
    ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };
  hardware.enableRedistributableFirmware = true;

}
// lib.optionalAttrs (!minimal) {

  guests = lib.concatMapAttrs (name: args: confLib.mkMicrovm name ({ withZfs = true; } // args)) {
    ankisync = { };
    atuin = { };
    audio.eternorPaths = [ "Music" ];
    dawarich = { };
    firefly = { };
    forgejo = { };
    freshrss = { };
    homebox = { };
    immich.eternorPaths = [ "Pictures" ];
    jellyfin.eternorPaths = [ "Videos" ];
    kanidm = { };
    kavita.eternorPaths = [ "Books" ];
    koillection = { };
    matrix = { };
    mealie = { };
    monitoring = { };
    nextcloud = { };
    paperless.eternorPaths = [ "Documents" ];
    radicale = { };
    storage.eternorPaths = [
      "Books"
      "Videos"
      "Music"
      "Pictures"
      "Software"
      "Documents"
    ];
    transmission.eternorPaths = [
      "Books"
      "Videos"
      "Music"
      "Software"
    ];
    utility = { };
  };

  networking.nftables.firewall.zones.untrusted.interfaces = [
    "lan"
    "bmc"
  ];
}
