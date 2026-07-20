{
  flake.modules.nixos.server-network =
    { config, lib, ... }:
    let
      netConfig = config.repo.secrets.local.networking;
      netPrefix = "${if config.swarselsystems.isCloud then config.node.name else "home"}";
    in
    {
      options.swarselsystems.server = {
        localNetwork = lib.mkOption {
          default = "";
          type = lib.types.str;
        };
        netConfigName = lib.mkOption {
          default = "${netPrefix}-${config.swarselsystems.server.localNetwork}";
          readOnly = true;
          type = lib.types.str;
        };
        netConfigPrefix = lib.mkOption {
          default = netPrefix;
          readOnly = true;
          type = lib.types.str;
        };
      };
      config = {
        swarselsystems = {
          enabledServerModules = [ "network" ];
          server.localNetwork = netConfig.localNetwork or "";
        };
        globals = {
          hosts.${config.node.name} = {
            defaultGateway4 = netConfig.defaultGateway4 or null;
            defaultGateway6 = netConfig.defaultGateway6 or null;
            isHome = if (netPrefix == "home") then true else false;
            wanAddress4 = netConfig.wanAddress4 or null;
            wanAddress6 = netConfig.wanAddress6 or null;
          };
          networks = lib.mkIf config.swarselsystems.writeGlobalNetworks (
            lib.mapAttrs' (
              netName: net:
              lib.nameValuePair "${netPrefix}-${netName}" {
                hosts.${config.node.name} = {
                  inherit (net) id;
                  mac = net.mac or null;
                };
              }
            ) (lib.filterAttrs (_: net: net ? id) netConfig.networks)
          );
        };
        networking = {
          inherit (netConfig) hostId;
          enableIPv6 = lib.mkDefault true;
          firewall.enable = lib.mkDefault true;
          hostName = config.node.name;
          nftables.enable = lib.mkDefault false;
        };

      };
    }

  ;
}
