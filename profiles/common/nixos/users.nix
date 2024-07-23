{ pkgs, config, ... }:
{
  users = {
    mutableUsers = false;
    users.swarsel = {
      isNormalUser = true;
      description = "Leon S";
      hashedPasswordFile = config.sops.secrets.swarseluser.path;
      extraGroups = [ "networkmanager" "wheel" "lp" "audio" "video" "vboxusers" "scanner" ];
      packages = with pkgs; [ ];
    };
  };
}
