{ lib, config, ... }:
{
  options.swarselsystems.profiles.server.local = lib.mkEnableOption "is this a local server";
  config = lib.mkIf config.swarselsystems.profiles.server.local {
    swarselsystems.modules = {
      general = lib.mkDefault true;
      server = {
        dotfiles = lib.mkDefault true;
      };
    };
  };

}
