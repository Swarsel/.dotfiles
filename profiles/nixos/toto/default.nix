{ lib, config, ... }:
{
  options.swarselprofiles.toto = lib.mkEnableOption "is this a toto (setup) host";
  config = lib.mkIf config.swarselprofiles.toto {
    swarselmodules = {
      general = lib.mkDefault true;
      packages = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      users = lib.mkDefault true;
      sops = lib.mkDefault true;
      impermanence = lib.mkDefault true;
      lanzaboote = lib.mkDefault true;
      autologin = lib.mkDefault true;
      pii = lib.mkDefault true;
      server = {
        ssh = lib.mkDefault true;
      };
    };

  };

}
