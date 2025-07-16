{ lib, config, ... }:
{
  options.swarselprofiles.server.moonside = lib.mkEnableOption "is this a moonside server";
  config = lib.mkIf config.swarselprofiles.server.moonside {
    swarselmodules = {
      general = lib.mkDefault true;
      pii = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      sops = lib.mkDefault true;
      server = {
        general = lib.mkDefault true;
        packages = lib.mkDefault true;
        nginx = lib.mkDefault true;
        ssh = lib.mkDefault true;
        oauth2-proxy = lib.mkDefault true;
        croc = lib.mkDefault true;
        microbin = lib.mkDefault true;
        shlink = lib.mkDefault true;
      };
    };
  };

}
