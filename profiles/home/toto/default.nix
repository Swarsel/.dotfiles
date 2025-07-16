{ lib, config, ... }:
{
  options.swarselprofiles.toto = lib.mkEnableOption "is this a toto (setup) host";
  config = lib.mkIf config.swarselprofiles.toto {
    swarselmodules = {
      general = lib.mkDefault true;
      sops = lib.mkDefault true;
      ssh = lib.mkDefault true;
      kitty = lib.mkDefault true;
      git = lib.mkDefault true;
    };
  };

}
