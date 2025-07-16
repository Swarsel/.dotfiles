{ lib, config, ... }:
{
  options.swarselprofiles.server.local = lib.mkEnableOption "is this a local server";
  config = lib.mkIf config.swarselprofiles.server.local {
    swarselmodules = {
      general = lib.mkDefault true;
      server = {
        dotfiles = lib.mkDefault true;
      };
    };
  };

}
