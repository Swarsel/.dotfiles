{ lib, config, ... }:
{
  options.swarselprofiles.server = lib.mkEnableOption "is this a server";
  config = lib.mkIf config.swarselprofiles.server {
    swarselmodules = {
      general = lib.mkDefault true;
      lanzaboote = lib.mkDefault true;
      pii = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      btrfs = lib.mkDefault true;
      sops = lib.mkDefault true;
      boot = lib.mkDefault true;
      server = {
        general = lib.mkDefault true;
        network = lib.mkDefault true;
        diskEncryption = lib.mkDefault true;
        packages = lib.mkDefault true;
        ssh = lib.mkDefault true;
      };
    };
  };

}
