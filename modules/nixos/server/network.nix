{ lib, config, ... }:
let
  inherit (config.swarselsystems.server) localNetwork;
in
{
  options.swarselmodules.server.network = lib.mkEnableOption "enable server network config";
  options.swarselsystems.server.localNetwork = lib.mkOption {
    type = lib.types.str;
    default = "home";
  };
  config = lib.mkIf config.swarselmodules.server.network {

    globals.networks."${if config.swarselsystems.isCloud then config.node.name else "home"}-${localNetwork}".hosts.${config.node.name} = {
      inherit (config.repo.secrets.local.networking.networks.${localNetwork}) id;
      mac = config.repo.secrets.local.networking.networks.${localNetwork}.mac or null;
    };

    globals.hosts.${config.node.name} = {
      inherit (config.repo.secrets.local.networking) defaultGateway4;
      wanAddress4 = config.repo.secrets.local.networking.wanAddress4 or null;
      wanAddress6 = config.repo.secrets.local.networking.wanAddress6 or null;
    };

    networking = {
      inherit (config.repo.secrets.local.networking) hostId;
      hostName = config.node.name;
      nftables.enable = lib.mkDefault false;
      enableIPv6 = lib.mkDefault true;
      firewall = {
        enable = lib.mkDefault true;
      };
    };

  };
}
