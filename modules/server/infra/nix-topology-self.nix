{
  flake.modules.nixos.nix-topology-self =
    {
      config,
      lib,
      globals,
      ...
    }:
    let
      isWgParticipant =
        ifName:
        globals.wireguard ? ${ifName}
        && (
          builtins.elem config.node.name globals.wireguard.${ifName}.clients
          || globals.wireguard.${ifName}.server == config.node.name
        );
    in
    {
      topology.self = {
        icon = lib.mkIf config.swarselsystems.isCloud "devices.cloud-server";
        interfaces = {
          lan = lib.mkIf (
            config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "lan"
          ) { };
          wan = lib.mkIf (
            config.swarselsystems.isCloud && config.swarselsystems.server.localNetwork == "wan"
          ) { };
        }
        // lib.genAttrs [ "wgHome" "wgProxy" ] (
          ifName:
          lib.mkIf (isWgParticipant ifName) {
            addresses = [
              globals.networks."${
                globals.wireguard.${ifName}.netConfigPrefix
              }-${ifName}".hosts.${config.node.name}.ipv4
            ];
            renderer.hidePhysicalConnections = true;
            type = "wireguard";
            virtual = true;
          }
        );
      };
    };
}
