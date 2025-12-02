{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "dns-hostrecord"; proxy = config.node.name; }) serviceName proxyAddress4 proxyAddress6;
in
{
  options. swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.domains.main}.subdomainRecords = {
      "server.${config.node.name}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

  };
}
