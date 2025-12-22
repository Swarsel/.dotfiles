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
      interfaces = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
          options = {
            isServer = lib.mkEnableOption "set this interface as a wireguard server";
            isClient = lib.mkEnableOption "set this interface as a wireguard client";

            serverName = lib.mkOption {
              type = lib.types.str;
              default = "";
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

            peers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "WireGuard peer config names (clients when this host is server, or additional peers).";
            };
          };
        }));
        default = { };
        description = "WireGuard interfaces defined on this host.";
      };
    };
  };

  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    sops.secrets =
      lib.mkMerge (
        [
          {
            # shared host private key
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
              simpleClientSecrets =
                lib.optionalAttrs (i.isClient && i.peers == [ ]) {
                  "wireguard-${i.serverName}-${config.node.name}-${i.ifName}-presharedKey" = {
                    sopsFile = wgSopsFile;
                    owner = serviceUser;
                    group = serviceGroup;
                    mode = "0600";
                  };
                };

              multiPeerSecrets =
                lib.optionalAttrs (i.peers != [ ]) (builtins.listToAttrs (map
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
            simpleClientSecrets // multiPeerSecrets
          )
          ifaceList)
      );

    networking = {
      firewall.checkReversePath =
        lib.mkIf (lib.any (i: i.isClient) ifaceList) "loose";

      firewall.allowedUDPPorts =
        lib.mkIf (lib.any (i: i.isServer) ifaceList) [ servicePort ];
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

              address =
                if i.isServer then [
                  globals.networks."${config.swarselsystems.server.netConfigPrefix}-${ifName}".hosts.${config.node.name}.cidrv4
                  globals.networks."${config.swarselsystems.server.netConfigPrefix}-${ifName}".hosts.${config.node.name}.cidrv6
                ] else [
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
                      config.sops.secrets."wireguard-${config.node.name}-${clientName}-${i.ifName}-presharedKey".path;

                    AllowedIPs =
                      let
                        clientInWgNetwork =
                          globals.networks."${config.swarselsystems.server.netConfigPrefix}-${i.ifName}".hosts.${clientName};
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
