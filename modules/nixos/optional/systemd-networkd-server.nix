{ lib, config, globals, ... }:
{
  networking = {
    useDHCP = lib.mkForce false;
    useNetworkd = true;
    dhcpcd.enable = false;
    renameInterfacesByMac = lib.mapAttrs (_: v: v.mac) (
      config.repo.secrets.local.networking.networks or { }
    );
  };
  boot.initrd.systemd.network = {
    enable = true;
    networks."10-${config.swarselsystems.server.localNetwork}" = config.systemd.network.networks."10-${config.swarselsystems.server.localNetwork}";
  };

  systemd = {
    network = {
      enable = true;
      wait-online.enable = false;
      networks =
        let
          netConfig = config.repo.secrets.local.networking;
        in
        {
          "10-${config.swarselsystems.server.localNetwork}" = {
            address = [
              "${globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.cidrv4}"
              "${globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.cidrv6}"
            ];
            routes = [
              {
                Gateway = netConfig.defaultGateway6;
                GatewayOnLink = true;
              }
              {
                Gateway = netConfig.defaultGateway4;
                GatewayOnLink = true;
              }
            ];
            networkConfig = {
              IPv6PrivacyExtensions = true;
              IPv6AcceptRA = false;
            };
            matchConfig.MACAddress = netConfig.networks.${config.swarselsystems.server.localNetwork}.mac;
            linkConfig.RequiredForOnline = "routable";
          };
        };
    };
  };
}
