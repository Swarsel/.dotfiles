{
  flake.modules.nixos.systemd-networkd-server =
    {
      self,
      config,
      lib,
      globals,
      ...
    }:
    let
      inherit (config.swarselsystems) isCrypted localVLANs;
      inherit (globals.general) routerServer;

      isRouter = config.node.name == routerServer;
      ifName = config.swarselsystems.server.localNetwork;
    in
    {
      imports = [
        self.modules.nixos.systemd-networkd-base
      ];
      boot.initrd.systemd.network = lib.mkIf (isCrypted && ((localVLANs == [ ]) || isRouter)) {
        enable = true;
        networks."10-${ifName}" = config.systemd.network.networks."10-${ifName}";
      };
      systemd.network = {
        networks =
          let
            netConfig = config.repo.secrets.local.networking;
          in
          {
            "10-${ifName}" = lib.mkIf (isRouter || (localVLANs == [ ])) {
              # address = lib.optionals (isRouter || (localVLANs == [ ])) [
              address = [
                "${globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.cidrv4}"
                "${globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.cidrv6}"
              ];
              linkConfig.RequiredForOnline = "routable";
              matchConfig.MACAddress = netConfig.networks.${config.swarselsystems.server.localNetwork}.mac;
              networkConfig = {
                IPv6AcceptRA = false;
                IPv6PrivacyExtensions = true;
              };
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
            };
          };
        wait-online.enable = false;
      };
    }

  ;
}
