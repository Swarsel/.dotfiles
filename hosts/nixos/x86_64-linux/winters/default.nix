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
    nginx = true; # for php stuff
    acme = false; # cert handled by proxy
    wireguard = true;

    nfs = true;
    kavita = true;
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
    emacs = true;
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

}
