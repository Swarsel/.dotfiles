{ lib, config, pkgs, ... }:
let
  inherit (config.swarselsystems) mainUser homeDir;
  devices = config.swarselsystems.syncthing.syncDevices;
in
{
  options.swarselmodules.syncthing = lib.mkEnableOption "syncthing config";
  config = lib.mkIf config.swarselmodules.syncthing {
    services.syncthing = {
      enable = true;
      package = pkgs.stable.syncthing;
      user = mainUser;
      dataDir = homeDir;
      configDir = "${homeDir}/.config/syncthing";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        options = {
          urAccepted = -1;
        };
        inherit (config.swarselsystems.syncthing) devices;
        folders = {
          "Default Folder" = lib.mkDefault {
            path = "${homeDir}/Sync";
            inherit devices;
            id = "default";
          };
          "Obsidian" = {
            path = "${homeDir}/Nextcloud/Obsidian";
            inherit devices;
            id = "yjvni-9eaa7";
          };
          "Org" = {
            path = "${homeDir}/Nextcloud/Org";
            inherit devices;
            id = "a7xnl-zjj3d";
          };
          "Vpn" = {
            path = "${homeDir}/Vpn";
            inherit devices;
            id = "hgp9s-fyq3p";
          };
        };
      };
    };
  };
}
