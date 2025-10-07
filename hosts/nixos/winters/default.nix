{ lib, config, minimal, ... }:
{

  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  globals.hosts.${config.node.name}.ipv4 = config.repo.secrets.local.ipv4;

  networking = {
    inherit (config.repo.secrets.local) hostId;
    hostName = "winters";
    firewall.enable = true;
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  swarselsystems = {
    info = "ASRock J4105-ITX, 32GB RAM";
    flakePath = "/root/.dotfiles";
    isImpermanence = false;
    isSecureBoot = true;
    isCrypted = true;
    isBtrfs = false;
    isLinux = true;
    isNixos = true;
  };

} // lib.optionalAttrs (!minimal) {

  swarselprofiles = {
    server = true;
  };

  swarselmodules.server = {
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
  };

}
