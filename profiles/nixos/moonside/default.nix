{ lib, config, ... }:
{
  options.swarselsystems.profiles.server.moonside = lib.mkEnableOption "is this a moonside server";
  config = lib.mkIf config.swarselsystems.profiles.server.moonside {
    swarselsystems = {
      modules = {
        general = lib.mkDefault true;
        pii = lib.mkDefault true;
        home-manager = lib.mkDefault true;
        home-managerExtra = lib.mkDefault true;
        xserver = lib.mkDefault true;
        time = lib.mkDefault true;
        users = lib.mkDefault true;
        impermanence = lib.mkDefault true;
        server = {
          general = lib.mkDefault true;
          packages = lib.mkDefault true;
          sops = lib.mkDefault true;
          nginx = lib.mkDefault true;
          ssh = lib.mkDefault true;
          oauth2Proxy = lib.mkDefault true;
          croc = lib.mkDefault true;
        };
      };
    };
  };

}
