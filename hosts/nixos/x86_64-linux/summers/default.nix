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
    ./disk-config.nix

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    self.modules.nixos.systemd-networkd-server-home
    self.modules.nixos.microvm-host
  ]
  ++ lib.optionals (!minimal) [
    self.modules.nixos.profile-localserver
    self.modules.nixos.wireguard
    self.modules.nixos.restic
    self.modules.nixos.podman
    self.modules.nixos.opkssh
    self.modules.nixos.smartctl-exporter
    self.modules.nixos.zfs-exporter
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
    networkKernelModules = [ "igb" ];
    proxyHost = "twothreetunnel";
    rootDisk = "/dev/disk/by-id/ata-TS120GMTS420S_J024880123";
    server.restic.targets = {
      SwarselState = {
        # nextcloud stores all data in state dir and has no data that needs backup
        paths = lib.map (guest: "/Vault/guests/${guest}/state") (
          builtins.filter (name: name != "nextcloud") (builtins.attrNames config.guests)
        );
        repository = config.repo.secrets.local.resticRepoState;
      };
      SwarselStorage = {
        paths = [
          "/Vault/Eternor/Pictures"
          "/Vault/Eternor/Documents/paperless"
        ];
        repository = config.repo.secrets.local.resticRepoStorage;
      };
    };
    withMicroVMs = true;
    writeGlobalNetworks = false;
  };
  topology.self.interfaces = {
    "bmc" = { };
    "lan" = { };
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

  guests = lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
    { }
    // confLib.mkMicrovm "ankisync" { withZfs = true; }
    // confLib.mkMicrovm "atuin" { withZfs = true; }
    // confLib.mkMicrovm "audio" {
      eternorPaths = [ "Music" ];
      withZfs = true;
    }
    // confLib.mkMicrovm "firefly" { withZfs = true; }
    // confLib.mkMicrovm "forgejo" { withZfs = true; }
    // confLib.mkMicrovm "freshrss" { withZfs = true; }
    // confLib.mkMicrovm "homebox" { withZfs = true; }
    // confLib.mkMicrovm "immich" {
      eternorPaths = [ "Pictures" ];
      withZfs = true;
    }
    // confLib.mkMicrovm "jellyfin" {
      eternorPaths = [ "Videos" ];
      withZfs = true;
    }
    // confLib.mkMicrovm "kanidm" { withZfs = true; }
    // confLib.mkMicrovm "kavita" {
      eternorPaths = [ "Books" ];
      withZfs = true;
    }
    // confLib.mkMicrovm "koillection" { withZfs = true; }
    // confLib.mkMicrovm "matrix" { withZfs = true; }
    // confLib.mkMicrovm "mealie" { withZfs = true; }
    // confLib.mkMicrovm "monitoring" { withZfs = true; }
    // confLib.mkMicrovm "nextcloud" { withZfs = true; }
    // confLib.mkMicrovm "paperless" {
      eternorPaths = [ "Documents" ];
      withZfs = true;
    }
    // confLib.mkMicrovm "radicale" { withZfs = true; }
    // confLib.mkMicrovm "storage" {
      eternorPaths = [
        "Books"
        "Videos"
        "Music"
        "Pictures"
        "Software"
        "Documents"
      ];
      withZfs = true;
    }
    // confLib.mkMicrovm "transmission" {
      eternorPaths = [
        "Books"
        "Videos"
        "Music"
        "Software"
      ];
      withZfs = true;
    }
  );

  networking.nftables.firewall.zones.untrusted.interfaces = [
    "lan"
    "bmc"
  ];

}
