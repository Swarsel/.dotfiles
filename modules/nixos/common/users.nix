{ pkgs, config, lib, globals, minimal, ... }:
{
  options.swarselmodules.users = lib.mkEnableOption "user config";
  config = lib.mkIf config.swarselmodules.users {
    sops.secrets.main-user-hashed-pw = lib.mkIf (!config.swarselsystems.isPublic) { neededForUsers = true; };

    users = {
      mutableUsers = lib.mkIf (!minimal) false;
      users = {
        root = {
          inherit (globals.root) hashedPassword;
          # shell = pkgs.zsh;
        };
        "${config.swarselsystems.mainUser}" = {
          isNormalUser = true;
          description = "Leon S";
          password = lib.mkIf (minimal || config.swarselsystems.isPublic) "setup";
          hashedPasswordFile = lib.mkIf (!minimal && !config.swarselsystems.isPublic) config.sops.secrets.main-user-hashed-pw.path;
          extraGroups = [ "wheel" ] ++ lib.optionals (!minimal) [ "networkmanager" "syncthing" "docker" "lp" "audio" "video" "vboxusers" "libvirtd" "scanner" ];
          packages = with pkgs; [ ];
        };
      };
    };
  };
}
