{ lib, config, ... }:
{
  options.swarselsystems.profiles.toto = lib.mkEnableOption "is this a toto (setup) host";
  config = lib.mkIf config.swarselsystems.profiles.toto {
    swarselsystems.modules = {
      general = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      home-managerExtra = lib.mkDefault true;
      xserver = lib.mkDefault true;
      users = lib.mkDefault true;
      commonSops = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      lanzaboote = lib.mkDefault true;
      server = {
        ssh = lib.mkDefault true;
      };
      optional = {
        autologin = lib.mkDefault true;
      };
    };

  };

}
