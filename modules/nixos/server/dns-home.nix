{ globals, confLib, ... }:
let
  inherit (confLib.static) homeProxy;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "dns-home" ];

    networking.hosts = {
      ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv4} = [ "server.${homeProxy}.${globals.domains.main}" ];
      ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv6} = [ "server.${homeProxy}.${globals.domains.main}" ];
    };

  };

}
