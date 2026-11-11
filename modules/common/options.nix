{
  flake.modules.generic.options =
    {
      root,
      config,
      lib,
      ...
    }:
    {
      options.swarselsystems = {
        bridgedVLANs = lib.mkOption {
          default = [ ];
          description = "Home VLANs that get a `br-<name>` bridge on this host.";
          type = lib.types.listOf lib.types.str;
        };
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
          default = "${config.swarselsystems.homeDir}/.dotfiles";
          type = lib.types.str;
        };
        highResolution = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        homeDir = lib.mkOption {
          default = "/home/${config.swarselsystems.mainUser}";
          type = lib.types.str;
        };
        # @ future me: dont put initrdVLAN or localVLANs under server prefix
        # home-manager would then try to import all swarselsystems.server.* options
        initrdVLAN = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.str;
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
        isFullBuild = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        isImpermanence = lib.mkEnableOption "use impermanence on this system";
        isLaptop = lib.mkEnableOption "laptop host";
        isLinux = lib.mkEnableOption "linux host";
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
        microVMPool = lib.mkOption {
          default = config.swarselsystems.storagePool;
          description = "ZFS pool for the persist and state datasets of the guests.";
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
        storagePool = lib.mkOption {
          description = "ZFS pool for the storage datasets shared into the guests.";
          type = lib.types.str;
        };
        swapSize = lib.mkOption {
          default = "8G";
          type = lib.types.str;
        };
        wallpaper = lib.mkOption {
          default = root "files/wallpaper/landscape/lenovowp.png";
          type = lib.types.path;
        };
        wifiMac = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.str;
        };
        withMicroVMs = lib.mkEnableOption "enable MicroVMs on this host";
        writeGlobalNetworks = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
      };
    };
}
