{ lib, config, ... }:
{
  options.swarselprofiles.router = lib.mkEnableOption "enable the router profile";
  config = lib.mkIf config.swarselprofiles.router {
    swarselmodules = {
      server = {
        router = lib.mkDefault true;
      };
    };
  };

}
