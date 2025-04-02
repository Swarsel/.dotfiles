{ lib, config, ... }:
{
  options.swarselsystems.profiles.server.sync = lib.mkEnableOption "is this a oci sync server";
  config = lib.mkIf config.swarselsystems.profiles.server.sync {
    swarselsystems = {
      # common modules
      modules = {
        nix-ld = lib.mkDefault true;
        home-manager = lib.mkDefault true;
        home-managerExtra = lib.mkDefault true;
        xserver = lib.mkDefault true;
        gc = lib.mkDefault true;
        storeOptimize = lib.mkDefault true;
        time = lib.mkDefault true;
        users = lib.mkDefault true;
      };
      # server modules
      # server = {
      #   forgejo = lib.mkDefault true;
      #   ankisync = lib.mkDefault true;
      # };
    };
  };

}
