{ self, lib, config, globals, ... }:
let
  inherit (config.swarselsystems) isCrypted localVLANs;
  inherit (globals.general) routerServer;

  isRouter = config.node.name == routerServer;
  ifName = config.swarselsystems.server.localNetwork;
in
{
  imports = [
    "${self}/modules/nixos/optional/systemd-networkd-base.nix"
  ];

  boot.initrd.systemd.network = lib.mkIf (isCrypted && ((localVLANs == [ ]) || isRouter)) {
    enable = true;
    networks."10-${ifName}" = config.systemd.network.networks."10-${ifName}";
  };

  systemd = {
    network = {
      wait-online.enable = false;
      networks =
        let
          netConfig = config.repo.secrets.local.networking;
        in
        {
          "10-${ifName}" = lib.mkIf (isRouter || (localVLANs == [ ])) {
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
