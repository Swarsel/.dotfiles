{ self, config, lib, ... }:
{
  options.swarselsystems = {
    withHomeManager = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    isSwap = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "8G";
    };
    rootDisk = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    mainUser = lib.mkOption {
      type = lib.types.str;
      default = "swarsel";
    };
    isCrypted = lib.mkEnableOption "uses full disk encryption";

    isImpermanence = lib.mkEnableOption "use impermanence on this system";
    isSecureBoot = lib.mkEnableOption "use secure boot on this system";
    isLaptop = lib.mkEnableOption "laptop host";
    isNixos = lib.mkEnableOption "nixos host";
    isPublic = lib.mkEnableOption "is a public machine (no secrets)";
    isDarwin = lib.mkEnableOption "darwin host";
    isLinux = lib.mkEnableOption "whether this is a linux machine";
    isBtrfs = lib.mkEnableOption "use btrfs filesystem";
    sopsFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.swarselsystems.flakePath}/secrets/${config.node.name}/secrets.yaml";
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
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = "${self}/files/wallpaper/lenovowp.png";
    };
    sharescreen = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    lowResolution = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    highResolution = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
}
