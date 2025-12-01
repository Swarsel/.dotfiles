{ lib, minimal, ... }:
{

  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  # globals.hosts.${config.node.name}.ipv4 = config.repo.secrets.local.ipv4;
  # globals.networks.home.hosts.${config.node.name} = {
  #   ipv4 = config.repo.secrets.local.home-ipv4;
  #   mac = config.repo.secrets.local.home-mac;
  # };

  swarselsystems = {
    info = "ASRock J4105-ITX, 32GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = false;
    isSecureBoot = false;
    isCrypted = false;
    isBtrfs = false;
    isLinux = true;
    isNixos = true;
    proxyHost = "moonside";
    server = {
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
