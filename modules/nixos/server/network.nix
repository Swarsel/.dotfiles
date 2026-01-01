{ lib, config, ... }:
let
  netConfig = config.repo.secrets.local.networking;
  netPrefix = "${if config.swarselsystems.isCloud then config.node.name else "home"}";
  # netName = "${netPrefix}-${config.swarselsystems.server.localNetwork}";
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

    # globals.networks.${netName}.hosts.${config.node.name} = {
    #   inherit (netConfig.networks.${netConfig.localNetwork}) id;
    #   mac = netConfig.networks.${netConfig.localNetwork}.mac or null;
    # };

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
      inherit (config.repo.secrets.local.networking) defaultGateway4;
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
