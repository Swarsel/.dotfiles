{ lib, config, ... }:
let
  netConfig = config.repo.secrets.local.networking;
  netPrefix = "${if config.swarselsystems.isCloud then config.node.name else "home"}";
in
{
  options = {
    swarselmodules.server.network = lib.mkEnableOption "enable server network config";
    swarselsystems.server = {
      localNetwork = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      netConfigName = lib.mkOption {
        type = lib.types.str;
        default = "${netPrefix}-${config.swarselsystems.server.localNetwork}";
        readOnly = true;
      };
      netConfigPrefix = lib.mkOption {
        type = lib.types.str;
        default = netPrefix;
        readOnly = true;
      };
    };
  };
  config = lib.mkIf config.swarselmodules.server.network {

    swarselsystems.server.localNetwork = netConfig.localNetwork or "";

    globals.networks = lib.mapAttrs'
      (netName: _:
        lib.nameValuePair "${netPrefix}-${netName}" {
          hosts.${config.node.name} = {
            inherit (netConfig.networks.${netName}) id;
            mac = netConfig.networks.${netName}.mac or null;
          };
        }
      )
      netConfig.networks;

    globals.hosts.${config.node.name} = {
      defaultGateway4 = netConfig.defaultGateway4 or null;
      defaultGateway6 = netConfig.defaultGateway6 or null;
      wanAddress4 = netConfig.wanAddress4 or null;
      wanAddress6 = netConfig.wanAddress6 or null;
      isHome = if (netPrefix == "home") then true else false;
    };

    networking = {
      inherit (netConfig) hostId;
      hostName = config.node.name;
      nftables.enable = lib.mkDefault false;
      enableIPv6 = lib.mkDefault true;
      firewall = {
        enable = lib.mkDefault true;
      };
    };

  };
}
