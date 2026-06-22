{
  self,
  config,
  inputs,
  lib,
  minimal,
  confLib,
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

  topology.self = {
    interfaces = {
      "lan" = { };
      "bmc" = { };
    };
  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "vfio-pci.ids=13f6:8788"
    ];
    initrd.kernelModules = [
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio"
    ];
    blacklistedKernelModules = [
      "snd_virtuoso"
      "snd_oxygen"
    ];
  };

  hardware.enableRedistributableFirmware = true;

  swarselsystems = {
    info = "ASUS Z10PA-D8, 2* Intel Xeon E5-2650 v4, 128GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = true;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = true;
    isLinux = true;
    isSwap = false;
    proxyHost = "twothreetunnel";
    writeGlobalNetworks = false;
    networkKernelModules = [ "igb" ];
    rootDisk = "/dev/disk/by-id/ata-TS120GMTS420S_J024880123";
    withMicroVMs = true;
    localVLANs = [
      "services"
      "home"
    ]; # devices is only provided on interface for bmc
    initrdVLAN = "home";
    server = {
      restic.targets = {
        SwarselState = {
          repository = config.repo.secrets.local.resticRepoState;
          # nextcloud stores all data in state dir and has no data that needs backup
          paths = lib.map (guest: "/Vault/guests/${guest}/state") (
            builtins.filter (name: name != "nextcloud") (builtins.attrNames config.guests)
          );
        };
        SwarselStorage = {
          repository = config.repo.secrets.local.resticRepoStorage;
          paths = [
            "/Vault/Eternor/Pictures"
            "/Vault/Eternor/Documents/paperless"
          ];
        };
      };
    };
  };

}
// lib.optionalAttrs (!minimal) {

  guests = lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
    { }
    // confLib.mkMicrovm "ankisync" { withZfs = true; }
    // confLib.mkMicrovm "atuin" { withZfs = true; }
    // confLib.mkMicrovm "audio" {
      withZfs = true;
      eternorPaths = [ "Music" ];
    }
    // confLib.mkMicrovm "firefly" { withZfs = true; }
    // confLib.mkMicrovm "forgejo" { withZfs = true; }
    // confLib.mkMicrovm "freshrss" { withZfs = true; }
    // confLib.mkMicrovm "homebox" { withZfs = true; }
    // confLib.mkMicrovm "immich" {
      withZfs = true;
      eternorPaths = [ "Pictures" ];
    }
    // confLib.mkMicrovm "jellyfin" {
      withZfs = true;
      eternorPaths = [ "Videos" ];
    }
    // confLib.mkMicrovm "kanidm" { withZfs = true; }
    // confLib.mkMicrovm "kavita" {
      withZfs = true;
      eternorPaths = [ "Books" ];
    }
    // confLib.mkMicrovm "koillection" { withZfs = true; }
    // confLib.mkMicrovm "matrix" { withZfs = true; }
    // confLib.mkMicrovm "mealie" { withZfs = true; }
    // confLib.mkMicrovm "monitoring" { withZfs = true; }
    // confLib.mkMicrovm "nextcloud" { withZfs = true; }
    // confLib.mkMicrovm "paperless" {
      withZfs = true;
      eternorPaths = [ "Documents" ];
    }
    // confLib.mkMicrovm "radicale" { withZfs = true; }
    // confLib.mkMicrovm "storage" {
      withZfs = true;
      eternorPaths = [
        "Books"
        "Videos"
        "Music"
        "Pictures"
        "Software"
        "Documents"
      ];
    }
    // confLib.mkMicrovm "transmission" {
      withZfs = true;
      eternorPaths = [
        "Books"
        "Videos"
        "Music"
        "Software"
      ];
    }
  );

  networking.nftables.firewall.zones.untrusted.interfaces = [
    "lan"
    "bmc"
  ];

}
