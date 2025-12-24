{ lib, config, ... }:
{
  options.swarselprofiles.router = lib.mkEnableOption "enable the router profile";
  config = lib.mkIf config.swarselprofiles.router {
    swarselmodules = {
      nftables = lib.mkDefault true;
      server = {
        router = lib.mkDefault true;
        kea = lib.mkDefault true;
      };
    };
  };

}
