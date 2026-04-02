{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "dns-home"; }) serviceName;
  inherit (confLib.static) homeProxy;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    networking.hosts = {
      ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv4} = [ "server.${homeProxy}.${globals.domains.main}" ];
      ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv6} = [ "server.${homeProxy}.${globals.domains.main}" ];
    };

  };

}
