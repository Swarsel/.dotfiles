{ self, config, inputs, lib, minimal, confLib, ... }:
{

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    "${self}/modules/nixos/optional/systemd-networkd-server-home.nix"
    "${self}/modules/nixos/optional/microvm-host.nix"
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
    isNixos = true;
    isSwap = false;
    proxyHost = "twothreetunnel";
    writeGlobalNetworks = false;
    networkKernelModules = [ "igb" ];
    rootDisk = "/dev/disk/by-id/ata-TS120GMTS420S_J024880123";
    withMicroVMs = true;
    localVLANs = [ "services" "home" ]; # devices is only provided on interface for bmc
    initrdVLAN = "home";
    server = {
      wireguard.interfaces = {
        wgProxy = {
          isClient = true;
          serverName = "twothreetunnel";
        };
        wgHome = {
          isClient = true;
          serverName = "hintbooth";
        };
      };
      restic = {
        bucketName = "SwarselWinters";
        paths = [
          "/Vault/data/paperless"
          "/Vault/data/koillection"
          "/Vault/data/postgresql"
          "/Vault/data/firefly-iii"
          "/Vault/data/radicale"
          "/Vault/data/matrix-synapse"
          "/Vault/Eternor/Paperless"
          "/Vault/Eternor/Bilder"
          "/Vault/Eternor/Immich"
        ];
      };
    };
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    wireguard = true;

    nginx = true; # for php stuff
    acme = false; # cert handled by proxy

    nfs = true;
    # kavita = true;
    restic = true;
    jellyfin = true;
    navidrome = true;
    spotifyd = true;
    mpd = true;
    postgresql = true;
    matrix = true;
    nextcloud = true;
    immich = true;
    paperless = true;
    transmission = true;
    syncthing = true;
    grafana = true;
    freshrss = true;
    kanidm = true;
    firefly-iii = true;
    koillection = true;
    radicale = true;
    atuin = true;
    forgejo = true;
    ankisync = true;
    homebox = true;
    opkssh = true;
  };

  guests = lib.mkIf (!minimal && config.swarselsystems.withMicroVMs) (
    { }
    // confLib.mkMicrovm "kavita" { withZfs = true; }
    // confLib.mkMicrovm "jellyfin" { withZfs = true; }
    // confLib.mkMicrovm "audio" { withZfs = true; }
    // confLib.mkMicrovm "postgresql" { withZfs = true; }
    // confLib.mkMicrovm "matrix" { withZfs = true; }
    // confLib.mkMicrovm "nextcloud" { withZfs = true; }
    // confLib.mkMicrovm "immich" { withZfs = true; }
    // confLib.mkMicrovm "paperless" { withZfs = true; }
    // confLib.mkMicrovm "transmission" { withZfs = true; }
    // confLib.mkMicrovm "storage" { withZfs = true; }
    // confLib.mkMicrovm "monitoring" { withZfs = true; }
    // confLib.mkMicrovm "freshrss" { withZfs = true; }
    // confLib.mkMicrovm "kanidm" { withZfs = true; }
    // confLib.mkMicrovm "firefly" { withZfs = true; }
    // confLib.mkMicrovm "koillection" { withZfs = true; }
    // confLib.mkMicrovm "radicale" { withZfs = true; }
    // confLib.mkMicrovm "atuin" { withZfs = true; }
    // confLib.mkMicrovm "forgejo" { withZfs = true; }
    // confLib.mkMicrovm "ankisync" { withZfs = true; }
    // confLib.mkMicrovm "homebox" { withZfs = true; }
  );

  networking.nftables.firewall.zones.untrusted.interfaces = [ "lan" "bmc" ];

}
