{ lib, config, globals, ... }:
let
  isWgParticipant = ifName: globals.wireguard ? ${ifName} && (builtins.elem config.node.name globals.wireguard.${ifName}.clients || globals.wireguard.${ifName}.server == config.node.name);
in
{
  topology.self = {
    icon = lib.mkIf config.swarselsystems.isCloud "devices.cloud-server";
    interfaces = {
      wan = lib.mkIf (config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "wan") { };
      lan = lib.mkIf (config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "lan") { };
      wgProxy = lib.mkIf (isWgParticipant "wgProxy") {
        addresses = [ globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts.${config.node.name}.ipv4 ];
        renderer.hidePhysicalConnections = true;
        virtual = true;
        type = "wireguard";
      };
      wgHome = lib.mkIf (isWgParticipant "wgHome") {
        addresses = [ globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts.${config.node.name}.ipv4 ];
        renderer.hidePhysicalConnections = true;
        virtual = true;
        type = "wireguard";
      };
    };
  };
}
