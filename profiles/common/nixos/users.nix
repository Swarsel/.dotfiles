{ pkgs, config, lib, ... }:
{
  sops.secrets.swarseluser = { neededForUsers = true; };

  users = {
    mutableUsers = lib.mkIf (!config.swarselsystems.initialSetup) false;
    users.swarsel = {
      isNormalUser = true;
      description = "Leon S";
      hashedPasswordFile = lib.mkIf (!config.swarselsystems.initialSetup) config.sops.secrets.swarseluser.path;
      extraGroups = [ "networkmanager" "docker" "wheel" "lp" "audio" "video" "vboxusers" "scanner" ];
      packages = with pkgs; [ ];
    };
  };
}
