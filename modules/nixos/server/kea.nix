{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "kea"; dir = "/var/lib/private/kea"; }) serviceName serviceDir;
  dhcpX = intX:
    let
      x = builtins.toString intX;
    in
    {
      enable = true;
      settings = {
        lease-database = {
          name = "/var/lib/kea/dhcp${x}.leases";
          persist = true;
          type = "memfile";
        };
        valid-lifetime = 86400;
        renew-timer = 3600;
        interfaces-config = {
          interfaces = map (name: "me-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
          service-sockets-max-retries = -1;
        };
        "subnet${x}" = lib.flip lib.mapAttrsToList globals.networks.home-lan.vlans (
          vlanName: vlanCfg: {
            inherit (vlanCfg) id;
            interface = "me-${vlanName}";
            subnet = vlanCfg."cidrv${x}";
            pools = [
              {
                pool = "${lib.net.cidr.host 20 vlanCfg."cidrv${x}"} - ${lib.net.cidr.host (-6) vlanCfg."cidrv${x}"}";
              }
            ];
            option-data =
              lib.optional (intX == 4)
                {
                  name = "routers";
                  data = vlanCfg.hosts.hintbooth."ipv${x}"; # FIXME: how to advertise v6 address also?
                };
            # Advertise DNS server for VLANS that have internet access
            # ++
            # lib.optional
            #   (lib.elem vlanName [
            #     "services"
            #     "home"
            #     "devices"
            #     "guests"
            #   ])
            #   {
            #     name = "domain-name-servers";
            #     data = globals.networks.home-lan.vlans.services.hosts.hintbooth-adguardhome.ipv4;
            #   };
            reservations = lib.concatLists (
              lib.forEach (builtins.attrValues vlanCfg.hosts) (
                hostCfg:
                lib.optional (hostCfg.mac != null) {
                  hw-address = hostCfg.mac;
                  ip-address = lib.mkIf (intX == 4) hostCfg."ipv${x}";
                  ip-addresses = lib.mkIf (intX == 6) [ hostCfg."ipv${x}" ];
                }
              )
            );
          }
        );
      };
    };
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; mode = "0700"; }
    ];

    services.kea = {
      dhcp4 = dhcpX 4;
      dhcp6 = dhcpX 6;
    };

  };
}
