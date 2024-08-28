{ pkgs, config, lib, ... }:
{
  users = {
    mutableUsers = lib.mkIf (!config.swarselsystems.initialSetup) false;
    users.swarsel = {
      isNormalUser = true;
      description = "Leon S";
      hashedPasswordFile = lib.mkIf (!config.swarselsystems.initialSetup) config.sops.secrets.swarseluser.path;
      extraGroups = [ "networkmanager" "root" "docker" "wheel" "lp" "audio" "video" "vboxusers" "scanner" ];
      packages = with pkgs; [ ];
    };
  };
}
