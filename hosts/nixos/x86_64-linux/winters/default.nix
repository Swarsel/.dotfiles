{ self, lib, minimal, globals, ... }:
{

  imports = [
    ./hardware-configuration.nix

    "${self}/modules/nixos/optional/systemd-networkd-server.nix"
    "${self}/modules/nixos/optional/nix-topology-self.nix"
  ];

  topology.self.interfaces."eth1" = { };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  networking.hosts = {
    ${globals.networks.home-lan.hosts.hintbooth.ipv4} = [ "server.hintbooth.${globals.domains.main}" ];
    ${globals.networks.home-lan.hosts.hintbooth.ipv6} = [ "server.hintbooth.${globals.domains.main}" ];
  };

  swarselsystems = {
    info = "ASRock J4105-ITX, 32GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = false;
    isSecureBoot = false;
    isCrypted = false;
    isBtrfs = false;
    isLinux = true;
    isNixos = true;
    proxyHost = "twothreetunnel";
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
      garage = {
        data_dir = {
          capacity = "200G";
          path = "/Vault/data/garage/data";
        };
      };
    };
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
    diskEncryption = lib.mkForce false;
    wireguard = lib.mkDefault true;
    nfs = lib.mkDefault true;
    nginx = lib.mkDefault true;
    kavita = lib.mkDefault true;
    restic = lib.mkDefault true;
    jellyfin = lib.mkDefault true;
    navidrome = lib.mkDefault true;
    spotifyd = lib.mkDefault true;
    mpd = lib.mkDefault true;
    postgresql = lib.mkDefault true;
    matrix = lib.mkDefault true;
    nextcloud = lib.mkDefault true;
    immich = lib.mkDefault true;
    paperless = lib.mkDefault true;
    transmission = lib.mkDefault true;
    syncthing = lib.mkDefault true;
    grafana = lib.mkDefault true;
    emacs = lib.mkDefault true;
    freshrss = lib.mkDefault true;
    jenkins = lib.mkDefault false;
    kanidm = lib.mkDefault true;
    firefly-iii = lib.mkDefault true;
    koillection = lib.mkDefault true;
    radicale = lib.mkDefault true;
    atuin = lib.mkDefault true;
    forgejo = lib.mkDefault true;
    ankisync = lib.mkDefault true;
    # snipeit = lib.mkDefault false;
    homebox = lib.mkDefault true;
    opkssh = lib.mkDefault true;
    garage = lib.mkDefault false;
  };

}
