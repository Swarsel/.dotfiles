{ lib, config, ... }:
{
  options.swarselsystems.profiles.server.sync = lib.mkEnableOption "is this a oci sync server";
  config = lib.mkIf config.swarselsystems.profiles.server.sync {
    swarselsystems = {
      modules = {
        general = lib.mkDefault true;
        nix-ld = lib.mkDefault true;
        home-manager = lib.mkDefault true;
        home-managerExtra = lib.mkDefault true;
        xserver = lib.mkDefault true;
        time = lib.mkDefault true;
        users = lib.mkDefault true;
        server = {
          general = lib.mkDefault true;
          packages = lib.mkDefault true;
          sops = lib.mkDefault true;
          nfs = lib.mkDefault true;
          nginx = lib.mkDefault true;
          ssh = lib.mkDefault true;
          forgejo = lib.mkDefault true;
          ankisync = lib.mkDefault true;
        };
      };
    };
  };

}
