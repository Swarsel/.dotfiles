{ self, pkgs, config, lib, minimal, ... }:
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
        password = lib.mkIf (config.swarselsystems.initialSetup || minimal) "setup";
        hashedPasswordFile = lib.mkIf (!config.swarselsystems.initialSetup && !minimal) config.sops.secrets.swarseluser.path;
        extraGroups = [ "wheel" ] ++ lib.optionals (!minimal) [ "networkmanager" "syncthing" "docker" "lp" "audio" "video" "vboxusers" "libvirtd" "scanner" ];
        packages = with pkgs; [ ];
      };
    };
  };
}
