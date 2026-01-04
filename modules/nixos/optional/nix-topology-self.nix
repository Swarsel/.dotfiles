{ lib, config, globals, confLib, ... }:
let
  inherit (confLib.static) webProxy;
in
{
  topology.self = {
    icon = lib.mkIf config.swarselsystems.isCloud "devices.cloud-server";
    interfaces = {
      wan = lib.mkIf (config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "wan") { };
      lan = lib.mkIf (config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "lan") { };
      wgProxy = lib.mkIf (config.swarselsystems.server.wireguard ? wgHome) {
        addresses = [ globals.networks."${webProxy}-wg.hosts".${config.node.name}.ipv4 ];
        renderer.hidePhysicalConnections = true;
        virtual = true;
        type = "wireguard";
      };
      wgHome = lib.mkIf (config.swarselsystems.server.wireguard ? wgHome) {
        addresses = [ globals.networks.home-wgHome.hosts.${config.node.name}.ipv4 ];
        renderer.hidePhysicalConnections = true;
        virtual = true;
        type = "wireguard";
      };
    };
  };
}
