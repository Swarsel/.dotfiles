{ self, lib, pkgs, config, confLib, nodes, globals, ... }:
let
  inherit (confLib.gen {
    name = "wireguard";
    port = 52829;
    user = "systemd-network";
    group = "systemd-network";
  }) servicePort serviceName serviceUser serviceGroup;

  inherit (config.swarselsystems) sopsFile;
  wgSopsFile = self + "/secrets/repo/wg.yaml";

  cfg = config.swarselsystems.server.wireguard;
  inherit (cfg) interfaces;
  ifaceList = builtins.attrValues interfaces;
in
{
  options = {
    swarselmodules.server.${serviceName} =
      lib.mkEnableOption "enable ${serviceName} settings";

    swarselsystems.server.wireguard = {
      interfaces =
        let
          topConfig = config;
        in
        lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ config, name, ... }: {
            options = {
              isServer = lib.mkEnableOption "set this interface as a wireguard server";
              isClient = lib.mkEnableOption "set this interface as a wireguard client";

              serverName = lib.mkOption {
                type = lib.types.str;
                default = if config.isServer then topConfig.node.name else "";
                description = "Hostname of the WireGuard server this interface connects to (when isClient = true).";
              };

              serverNetConfigPrefix = lib.mkOption {
                type = lib.types.str;
                default =
                  let
                    serverCfg = nodes.${config.serverName}.config;
                  in
                  if serverCfg.swarselsystems.isCloud
                  then serverCfg.node.name
                  else "home";
                readOnly = true;
                description = "Prefix used to look up the server network in globals.networks.\"<prefix>-wg\".";
              };

              ifName = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Name of the WireGuard interface.";
              };

              port = lib.mkOption {
                type = lib.types.int;
                default = servicePort;
                description = "Port of the WireGuard interface.";
              };

              peers = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = lib.attrNames (lib.filterAttrs (name: _: name != topConfig.node.name) globals.networks."${config.serverNetConfigPrefix}-${config.ifName}".hosts);
                description = "WireGuard peer config names of this wireguardinterface.";
              };
            };
          }));
          default = { };
          description = "WireGuard interfaces defined on this host.";
        };
    };
  };

  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    assertions = lib.concatLists (
      lib.flip lib.mapAttrsToList interfaces (
        ifName: ifCfg:
          let
            assertionPrefix = "While evaluating the wireguard network ${ifName}:";
          in
          [
            {
              assertion = ifCfg.isServer || (ifCfg.isClient && ifCfg.serverName != "");
              message = "${assertionPrefix}: This node must either be a server for the wireguard network or a client with serverName set.";
            }
            {
              assertion = lib.stringLength ifName < 16;
              message = "${assertionPrefix}: The specified linkName '${ifName}' is too long (must be max 15 characters).";
            }
          ]
      )
    );

    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    sops.secrets =
      lib.mkMerge (
        [
          {
            wireguard-private-key = {
              inherit sopsFile;
              owner = serviceUser;
              group = serviceGroup;
              mode = "0600";
            };
          }
        ] ++ (map
          (i:
            let
              clientSecrets =
                lib.optionalAttrs i.isClient {
                  "wireguard-${i.serverName}-${config.node.name}-${i.ifName}-presharedKey" = {
                    sopsFile = wgSopsFile;
                    owner = serviceUser;
                    group = serviceGroup;
                    mode = "0600";
                  };
                };

              serverSecrets =
                lib.optionalAttrs i.isServer (builtins.listToAttrs (map
                  (clientName: {
                    name = "wireguard-${config.node.name}-${clientName}-${i.ifName}-presharedKey";
                    value = {
                      sopsFile = wgSopsFile;
                      owner = serviceUser;
                      group = serviceGroup;
                      mode = "0600";
                    };
                  })
                  i.peers));
            in
            clientSecrets // serverSecrets
          )
          ifaceList)
      );

    networking.firewall = {
      checkReversePath = lib.mkIf (lib.any (i: i.isClient) ifaceList) "loose";
      allowedUDPPorts = lib.mkMerge (
        lib.flip lib.mapAttrsToList interfaces (
          _: ifCfg:
            lib.optional ifCfg.isServer ifCfg.port
        )
      );
    };

    networking.nftables.firewall = {
      zones = lib.mkMerge
        (
          lib.flip lib.mapAttrsToList interfaces (
            ifName: ifCfg:
              {
                ${ifName}.interfaces = [ ifName ];
              }
              // lib.listToAttrs (map
                (peer:
                  let
                    peerNet = globals.networks."${ifCfg.serverNetConfigPrefix}-${ifName}".hosts.${peer};
                  in
                  lib.nameValuePair "${ifName}-node-${peer}" {
                    parent = ifName;
                    ipv4Addresses = lib.optional (peerNet.ipv4 != null) peerNet.ipv4;
                    ipv6Addresses = lib.optional (peerNet.ipv6 != null) peerNet.ipv6;
                  }
                )
                ifCfg.peers)
          )
        );
      rules = lib.mkMerge (
        lib.flip lib.mapAttrsToList interfaces (
          ifName: ifCfg:
            let
              inherit (config.networking.nftables.firewall) localZoneName;
              netCfg = globals.networks."${ifCfg.serverNetConfigPrefix}-${ifName}";
            in
            {
              "${ifName}-to-${localZoneName}" = {
                inherit (netCfg.firewallRuleForAll) allowedTCPPorts allowedUDPPorts allowedTCPPortRanges allowedUDPPortRanges;
                from = [ ifName ];
                to = [ localZoneName ];
                ignoreEmptyRule = true;
              };
            }
            // lib.listToAttrs (map
              (peer:
                lib.nameValuePair "${ifName}-node-${peer}-to-${localZoneName}" (
                  lib.mkIf (netCfg.hosts.${config.node.name}.firewallRuleForNode ? ${peer}) {
                    inherit (netCfg.hosts.${config.node.name}.firewallRuleForNode.${peer}) allowedTCPPorts allowedTCPPortRanges allowedUDPPorts allowedUDPPortRanges;
                    from = [ "${ifName}-node-${peer}" ];
                    to = [ localZoneName ];
                    ignoreEmptyRule = true;
                  }
                )
              )
              ifCfg.peers)
        )
      );
    };

    systemd.network = {
      enable = true;

      networks = lib.mkMerge (map
        (i:
          let
            inherit (i) ifName;
          in
          {
            "50-${ifName}" = {
              matchConfig.Name = ifName;
              linkConfig = {
                MTUBytes = 1408; # TODO: figure out where we lose those 12 bits (8 from pppoe maybe + ???)
              };

              address = [
                globals.networks."${i.serverNetConfigPrefix}-${ifName}".hosts.${config.node.name}.cidrv4
                globals.networks."${i.serverNetConfigPrefix}-${ifName}".hosts.${config.node.name}.cidrv6
              ];
            };
          })
        ifaceList);

      netdevs = lib.mkMerge (map
        (i:
          let
            inherit (i) ifName;
          in
          {
            "50-${ifName}" = {
              netdevConfig = {
                Kind = "wireguard";
                Name = ifName;
              };

              wireguardConfig = {
                ListenPort = lib.mkIf i.isServer servicePort;

                PrivateKeyFile = config.sops.secrets.wireguard-private-key.path;

                RouteTable = lib.mkIf i.isClient "main";
              };

              wireguardPeers =
                lib.optionals i.isClient [
                  {
                    PublicKey =
                      builtins.readFile "${self}/secrets/public/wg/${i.serverName}.pub";

                    PresharedKeyFile =
                      config.sops.secrets."wireguard-${i.serverName}-${config.node.name}-${i.ifName}-presharedKey".path;

                    Endpoint =
                      "server.${i.serverName}.${globals.domains.main}:${toString servicePort}";

                    PersistentKeepalive = 25;

                    AllowedIPs =
                      let
                        wgNetwork = globals.networks."${i.serverNetConfigPrefix}-${i.ifName}";
                      in
                      (lib.optional (wgNetwork.cidrv4 != null) wgNetwork.cidrv4)
                      ++ (lib.optional (wgNetwork.cidrv6 != null) wgNetwork.cidrv6);
                  }
                ]
                ++ lib.optionals i.isServer (map
                  (clientName: {
                    PublicKey =
                      builtins.readFile "${self}/secrets/public/wg/${clientName}.pub";

                    PresharedKeyFile =
                      config.sops.secrets."wireguard-${i.serverName}-${clientName}-${i.ifName}-presharedKey".path;

                    AllowedIPs =
                      let
                        clientInWgNetwork =
                          globals.networks."${i.serverNetConfigPrefix}-${i.ifName}".hosts.${clientName};
                      in
                      (lib.optional (clientInWgNetwork.ipv4 != null)
                        (lib.net.cidr.make 32 clientInWgNetwork.ipv4))
                      ++ (lib.optional (clientInWgNetwork.ipv6 != null)
                        (lib.net.cidr.make 128 clientInWgNetwork.ipv6));
                  })
                  i.peers);
            };
          })
        ifaceList);
    };
  };
}
