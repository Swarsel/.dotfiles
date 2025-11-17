{ lib, config, ... }:
{
  options.swarselmodules.server.network = lib.mkEnableOption "enable server network config";
  config = lib.mkIf config.swarselmodules.server.network {

    globals.networks.home.hosts.${config.node.name} = {
      inherit (config.repo.secrets.local.networking.networks.home) id;
      mac = config.repo.secrets.local.networking.networks.home.mac or null;
    };

    globals.hosts.${config.node.name} = {
      inherit (config.repo.secrets.local.networking) defaultGateway4;
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
