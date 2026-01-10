{ self, config, lib, ... }:
{
  options.swarselsystems = {
    proxyHost = lib.mkOption {
      type = lib.types.str;
      default = config.node.name;
    };
    isBastionTarget = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    isCloud = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    isServer = lib.mkOption {
      type = lib.types.bool;
      default = config.swarselsystems.isCloud;
    };
    isClient = lib.mkOption {
      type = lib.types.bool;
      default = config.swarselsystems.isLaptop;
    };
    isMicroVM = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    isSwap = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    writeGlobalNetworks = lib.mkOption {
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
    # @ future me: dont put this under server prefix
    # home-manager would then try to import all swarselsystems.server.* options
    localVLANs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    # @ future me: dont put this under server prefix
    # home-manager would then try to import all swarselsystems.server.* options
    initrdVLAN = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    mainUser = lib.mkOption {
      type = lib.types.str;
      default = "swarsel";
    };
    isCrypted = lib.mkEnableOption "uses full disk encryption";
    withMicroVMs = lib.mkEnableOption "enable MicroVMs on this host";

    isImpermanence = lib.mkEnableOption "use impermanence on this system";
    isSecureBoot = lib.mkEnableOption "use secure boot on this system";
    isLaptop = lib.mkEnableOption "laptop host";
    isNixos = lib.mkEnableOption "nixos host";
    isPublic = lib.mkEnableOption "is a public machine (no secrets)";
    isDarwin = lib.mkEnableOption "darwin host";
    isLinux = lib.mkEnableOption "whether this is a linux machine";
    isBtrfs = lib.mkEnableOption "use btrfs filesystem";
    sopsFile = lib.mkOption {
      type = lib.types.either lib.types.str lib.types.path;
      # default = (if config.swarselsystems.isImpermanence then "/persist" else "") + config.node.secretsDir + "/secrets.yaml";
      default = config.node.secretsDir + "/secrets.yaml";
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
