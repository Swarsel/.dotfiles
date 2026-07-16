{
  flake.modules.generic.options =
    {
      self,
      config,
      lib,
      ...
    }:
    {
      options.swarselsystems = {
        enabledHomeModules = lib.mkOption {
          default = [ ];
          description = "List of enabled home module names, populated automatically by each module when imported. Used for cross-module checks.";
          type = lib.types.listOf lib.types.str;
        };
        enabledServerModules = lib.mkOption {
          default = [ ];
          description = "List of enabled server module names, populated automatically by each module when imported. Used for cross-module checks.";
          type = lib.types.listOf lib.types.str;
        };
        flakePath = lib.mkOption {
          default = "/home/swarsel/.dotfiles";
          type = lib.types.str;
        };
        highResolution = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        homeDir = lib.mkOption {
          default = "/home/swarsel";
          type = lib.types.str;
        };
        # @ future me: dont put this under server prefix
        # home-manager would then try to import all swarselsystems.server.* options
        initrdVLAN = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.str;
        };
        isBastionTarget = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
        isBtrfs = lib.mkEnableOption "use btrfs filesystem";
        isClient = lib.mkOption {
          default = config.swarselsystems.isLaptop;
          type = lib.types.bool;
        };
        isCloud = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
        isCrypted = lib.mkEnableOption "uses full disk encryption";
        isDarwin = lib.mkEnableOption "darwin host";
        isFullBuild = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        isImpermanence = lib.mkEnableOption "use impermanence on this system";
        isLaptop = lib.mkEnableOption "laptop host";
        isLinux = lib.mkEnableOption "whether this is a linux machine";
        isMicroVM = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
        isPublic = lib.mkEnableOption "is a public machine (no secrets)";
        isSecureBoot = lib.mkEnableOption "use secure boot on this system";
        isServer = lib.mkOption {
          default = config.swarselsystems.isCloud;
          type = lib.types.bool;
        };
        isSwap = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        # @ future me: dont put this under server prefix
        # home-manager would then try to import all swarselsystems.server.* options
        localVLANs = lib.mkOption {
          default = [ ];
          type = lib.types.listOf lib.types.str;
        };
        lowResolution = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        mainUser = lib.mkOption {
          default = "swarsel";
          type = lib.types.str;
        };
        nodeRoles = lib.mkOption {
          default = [ ];
          description = "List of roles this server fulfills in the infrastructure. Will set `globals.general.<itemName>` to the nodeName for each item.";
          type = lib.types.listOf lib.types.str;
        };
        proxyHost = lib.mkOption {
          default = config.node.name;
          type = lib.types.str;
        };
        rootDisk = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        sharescreen = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        sopsFile = lib.mkOption {
          # default = (if config.swarselsystems.isImpermanence then "/persist" else "") + config.node.secretsDir + "/secrets.yaml";
          default = config.node.secretsDir + "/secrets.yaml";
          type = lib.types.either lib.types.str lib.types.path;
        };
        swapSize = lib.mkOption {
          default = "8G";
          type = lib.types.str;
        };
        wallpaper = lib.mkOption {
          default = "${self}/files/wallpaper/landscape/lenovowp.png";
          type = lib.types.path;
        };
        withMicroVMs = lib.mkEnableOption "enable MicroVMs on this host";
        writeGlobalNetworks = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        xdgDir = lib.mkOption {
          default = "/run/user/1000";
          type = lib.types.str;
        };
      };
    };
}
