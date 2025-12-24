{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "kea"; dir = "/var/lib/private/kea"; }) serviceName serviceDir;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; mode = "0700"; }
    ];

    services.kea.dhcp4 = {
      enable = true;
      settings = {
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        valid-lifetime = 86400;
        renew-timer = 3600;
        interfaces-config = {
          # XXX: BUG: why does this bind other macvtaps?
          interfaces = map (name: "me-${name}") (builtins.attrNames globals.networks.home-lan.vlans);
          service-sockets-max-retries = -1;
        };
        subnet4 = lib.flip lib.mapAttrsToList globals.networks.home-lan.vlans (
          vlanName: vlanCfg: {
            inherit (vlanCfg) id;
            interface = "me-${vlanName}";
            subnet = vlanCfg.cidrv4;
            pools = [
              {
                pool = "${lib.net.cidr.host 20 vlanCfg.cidrv4} - ${lib.net.cidr.host (-6) vlanCfg.cidrv4}";
              }
            ];
            option-data =
              [
                {
                  name = "routers";
                  data = vlanCfg.hosts.hintbooth.ipv4; # FIXME: how to advertise v6 address also?
                }
              ];
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
                  ip-address = hostCfg.ipv4;
                }
              )
            );
          }
        );
      };
    };


  };
}
