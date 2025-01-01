{ pkgs, config, lib, ... }:
{
  sops.secrets.swarseluser = lib.mkIf (!config.swarselsystems.isPublic) { neededForUsers = true; };

  users = {
    mutableUsers = lib.mkIf (!config.swarselsystems.initialSetup) false;
    users.swarsel = {
      isNormalUser = true;
      description = "Leon S";
      password = lib.mkIf config.swarselsystems.initialSetup "setup";
      hashedPasswordFile = lib.mkIf (!config.swarselsystems.initialSetup) config.sops.secrets.swarseluser.path;
      extraGroups = [ "networkmanager" "syncthing" "docker" "wheel" "lp" "audio" "video" "vboxusers" "libvirtd" "scanner" ];
      packages = with pkgs; [ ];
    };
  };
}
