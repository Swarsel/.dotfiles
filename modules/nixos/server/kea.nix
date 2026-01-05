{ self, lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "kea"; dir = "/var/lib/private/kea"; }) serviceName serviceDir;
  inherit (confLib.static) homeDnsServer;
  dhcpX = intX:
    let
      x = builtins.toString intX;
    in
    {
      enable = true;
      settings = {
        reservations-out-of-pool = true;
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
            rapid-commit = lib.mkIf (intX == 6) true;
            pools = [
              {
                pool = "${lib.net.cidr.host 20 vlanCfg."cidrv${x}"} - ${lib.net.cidr.host (-6) vlanCfg."cidrv${x}"}";
              }
            ];
            pd-pools = lib.mkIf (intX == 6) [
              {
                prefix = builtins.replaceStrings [ "::" ] [ ":0:0:100::" ] (lib.head (lib.splitString "/" vlanCfg.cidrv6));
                prefix-len = 56;
                delegated-len = 64;
              }
            ];
            option-data =
              lib.optional (intX == 4)
                {
                  name = "routers";
                  data = vlanCfg.hosts.hintbooth."ipv${x}";
                }
              # Advertise DNS server for VLANS that have internet access
              ++
              lib.optional
                (lib.elem vlanName globals.general.internetVLANs)
                {
                  name = if (intX == 4) then "domain-name-servers" else "dns-servers";
                  data = globals.networks.home-lan.vlans.services.hosts.${homeDnsServer}."ipv${x}";
                };
            reservations = lib.concatLists (
              lib.forEach (builtins.attrValues vlanCfg.hosts) (
                hostCfg:
                lib.optional (hostCfg.mac != null) {
                  hw-address = lib.mkIf (intX == 4) hostCfg.mac;
                  duid = lib.mkIf (intX == 6) "00:03:00:01:${hostCfg.mac}"; # 00:03 = duid type 3; 00:01 = ethernet
                  ip-address = lib.mkIf (intX == 4) hostCfg."ipv${x}";
                  ip-addresses = lib.mkIf (intX == 6) [ hostCfg."ipv${x}" ];
                  prefixes = lib.mkIf (intX == 6) [
                    "${builtins.replaceStrings ["::"] [":0:0:${builtins.toString (256 + hostCfg.id)}::"] (lib.head (lib.splitString "/" vlanCfg.cidrv6))}/64"
                  ];
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

    topology = {
      extractors.kea.enable = false;
      self.services.${serviceName} = {
        name = lib.swarselsystems.toCapitalized serviceName;
        icon = "${self}/files/topology-images/${serviceName}.png";
      };
    };

    services.kea = {
      dhcp4 = dhcpX 4;
      dhcp6 = dhcpX 6;
    };

  };
}
