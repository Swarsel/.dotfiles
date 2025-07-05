{ lib, config, ... }:
{
  options.swarselsystems.profiles.toto = lib.mkEnableOption "is this a toto (setup) host";
  config = lib.mkIf config.swarselsystems.profiles.toto {
    swarselsystems.modules = {
      general = lib.mkDefault true;
      sops = lib.mkDefault true;
      ssh = lib.mkDefault true;
      kitty = lib.mkDefault true;
      git = lib.mkDefault true;
    };
  };

}
