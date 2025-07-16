{ lib, config, ... }:
{
  options.swarselprofiles.server.syncserver = lib.mkEnableOption "is this a oci syncserver server";
  config = lib.mkIf config.swarselprofiles.server.syncserver {
    swarselmodules = {
      general = lib.mkDefault true;
      nix-ld = lib.mkDefault true;
      pii = lib.mkDefault true;
      home-manager = lib.mkDefault true;
      xserver = lib.mkDefault true;
      time = lib.mkDefault true;
      users = lib.mkDefault true;
      sops = lib.mkDefault true;
      server = {
        general = lib.mkDefault true;
        packages = lib.mkDefault true;
        nginx = lib.mkDefault true;
        ssh = lib.mkDefault true;
        forgejo = lib.mkDefault false;
        ankisync = lib.mkDefault false;
      };
    };
  };

}
