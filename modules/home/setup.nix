{ lib, ... }:
{
  options.swarselsystems = {
    isDarwin = lib.mkEnableOption "darwin host";
    isLinux = lib.mkEnableOption "whether this is a linux machine";
    mainUser = lib.mkOption {
      type = lib.types.str;
      default = "swarsel";
    };
    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/swarsel";
    };
    xdgDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/1000";
    };
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "/home/swarsel/.dotfiles";
    };
  };
}
