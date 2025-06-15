{ self, pkgs, config, lib, ... }:
let
  sopsFile = self + /secrets/general/secrets.yaml;
in
{
  options.swarselsystems.modules.users = lib.mkEnableOption "user config";
  config = lib.mkIf config.swarselsystems.modules.users {
    sops.secrets.swarseluser = lib.mkIf (!config.swarselsystems.isPublic) { inherit sopsFile; neededForUsers = true; };

    users = {
      mutableUsers = lib.mkIf (!config.swarselsystems.initialSetup) false;
      users."${config.swarselsystems.mainUser}" = {
        isNormalUser = true;
        description = "Leon S";
        password = lib.mkIf config.swarselsystems.initialSetup "setup";
        hashedPasswordFile = lib.mkIf (!config.swarselsystems.initialSetup) config.sops.secrets.swarseluser.path;
        extraGroups = [ "networkmanager" "syncthing" "docker" "wheel" "lp" "audio" "video" "vboxusers" "libvirtd" "scanner" ];
        packages = with pkgs; [ ];
      };
    };
  };
}
