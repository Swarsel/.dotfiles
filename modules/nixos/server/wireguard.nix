{ self, lib, pkgs, config, confLib, globals, ... }:
let
  inherit (confLib.gen {
    name = "wireguard";
    port = 52829;
    user = "systemd-network";
    group = "systemd-network";
  }) servicePort serviceUser serviceGroup;

  inherit (config.swarselsystems) sopsFile;
  wgSopsFilePrefix = self + "/secrets/wireguard";

  # Derive interfaces from globals.wireguard based on this node's name
  interfaces = lib.mapAttrs
    (ifName: wgCfg:
      let
        isServer = wgCfg.server == config.node.name;
        isClient = builtins.elem config.node.name wgCfg.clients;
        peers =
          if isServer then wgCfg.clients
          else [ wgCfg.server ];
        netCfg = globals.networks."${wgCfg.netConfigPrefix}-${ifName}";
        ruleSources = lib.attrNames (netCfg.hosts.${config.node.name}.firewallRuleForNode or { });
      in
      {
        inherit isServer isClient ifName peers;
        serverName = wgCfg.server;
        serverNetConfigPrefix = wgCfg.netConfigPrefix;
        inherit (wgCfg) port;
        # we need to add the node-port rules to "clients" without doing it generically for all nodes
        # (because that blows up memory requirements enormously)
        # e.g. summers eval needs ~80G if we do this for all hosts, but less than 20G like this
        zonePeers = lib.unique (peers ++ ruleSources);
      }
    )
    (lib.filterAttrs
      (_: wgCfg:
        wgCfg.server == config.node.name || builtins.elem config.node.name wgCfg.clients
      )
      globals.wireguard);

  ifaceList = builtins.attrValues interfaces;
in
{
  options = {
    swarselsystems.server.wireguard.interfaces = lib.mkOption {
      type = lib.types.unspecified;
      readOnly = true;
      internal = true;
      default = interfaces;
      description = "Derived from globals.wireguard. Do not set directly.";
    };
  };

  config = {
    swarselsystems.enabledServerModules = [ "wireguard" ];

    assertions = lib.concatLists (
      lib.flip lib.mapAttrsToList interfaces (
        ifName: ifCfg:
          let
            assertionPrefix = "While evaluating the wireguard network ${ifName}:";
          in
          [
            {
              assertion = ifCfg.isServer || ifCfg.isClient;
              message = "${assertionPrefix}: This node must either be a server or a client for the wireguard network.";
            }
            {
              assertion = lib.stringLength ifName < 16;
              message = "${assertionPrefix}: The specified linkName '${ifName}' is too long (must be max 15 characters).";
            }
          ]
      )
    );

    topology.self.interfaces = lib.mapAttrs'
      (wgName: _:
        lib.nameValuePair "${wgName}" {
          network = wgName;
        }
      )
      config.swarselsystems.server.wireguard.interfaces;

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
                    sopsFile = wgSopsFilePrefix + "/${i.serverName}-${config.node.name}.yaml";
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
                      sopsFile = wgSopsFilePrefix + "/${config.node.name}-${clientName}.yaml";
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
                ifCfg.zonePeers)
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
            // lib.optionalAttrs ifCfg.isServer {
              "${ifName}-to-${ifName}" = {
                from = [ ifName ];
                to = [ ifName ];
                verdict = "accept";
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
              ifCfg.zonePeers)
        )
      );
    };

    boot.kernel.sysctl = lib.mkIf (lib.any (i: i.isServer) ifaceList) {
      "net.ipv4.conf.all.forwarding" = lib.mkDefault true;
      "net.ipv6.conf.all.forwarding" = lib.mkDefault true;
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
                MTUBytes = 1500 - 4 - 8 - 40 - 8 - 32;
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
