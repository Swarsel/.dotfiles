{ config, globals, ... }:
{
  topology.self = {
    icon = lib.mkIf config.swarselsystems.isCloud "devices.cloud-server";
    interfaces.wan = lib.mkIf config.swarselsystems.isCloud { };
    interfaces.wg = lib.mkIf (config.swarselsystems.server.wireguard.isClient || config.swarselsystems.server.wireguard.isServer) {
      addresses = [ globals.networks.twothreetunnel-wg.hosts.${config.node.name}.ipv4 ];
      renderer.hidePhysicalConnections = true;
      virtual = true;
      type = "wireguard";
    };
  };
}
