{ self, lib, pkgs, config, confLib, nodes, globals, ... }:
let
  wgInterface = "wg0";
  inherit (confLib.gen { name = "wireguard"; port = 52829; user = "systemd-network"; group = "systemd-network"; }) servicePort serviceName serviceUser serviceGroup;

  inherit (config.swarselsystems) sopsFile;
  wgSopsFile = self + "/secrets/repo/wg.yaml";
  inherit (config.swarselsystems.server.wireguard) peers isClient isServer serverName serverNetConfigPrefix ifName;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} settings";
    swarselsystems.server.wireguard = {
      isServer = lib.mkEnableOption "set this as a wireguard server";
      isClient = lib.mkEnableOption "set this as a wireguard client";
      serverName = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      serverNetConfigPrefix = lib.mkOption {
        type = lib.types.str;
        default = "${if nodes.${serverName}.config.swarselsystems.isCloud then nodes.${serverName}.config.node.name else "home"}";
        readOnly = true;
      };
      ifName = lib.mkOption {
        type = lib.types.str;
        default = wgInterface;
      };
      peers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Wireguard peer config names";
      };
    };

  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    sops = {
      secrets = {
        wireguard-private-key = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0600"; };
        # create this secret only if this is a simple client with only one peer (the server)
        "wireguard-${serverName}-${config.node.name}-presharedKey" = lib.mkIf (isClient && peers == [ ]) { sopsFile = wgSopsFile; owner = serviceUser; group = serviceGroup; mode = "0600"; };
      }
      # create these secrets only if this host has multiple peers
      // lib.optionalAttrs (peers != [ ]) (builtins.listToAttrs (map
        (clientName: {
          name = "wireguard-${config.node.name}-${clientName}-presharedKey";
          value = { sopsFile = wgSopsFile; owner = serviceUser; group = serviceGroup; mode = "0600"; };
        })
        peers));
    };

    networking = {
      firewall.checkReversePath = lib.mkIf isClient "loose";
      firewall.allowedUDPPorts = [ servicePort ];
      # nat = lib.mkIf (config.swarselsystems.isCloud && isServer) {
      #   enable = true;
      #   enableIPv6 = true;
      #   externalInterface = "enp0s6";
      #   internalInterfaces = [ ifName ];
      # };
      # interfaces.${ifName}.mtu = 1280; # the default (1420) is not enough!
    };

    systemd.network = {
      enable = true;

      networks."50-${ifName}" = {
        matchConfig.Name = ifName;
        linkConfig = {
          MTUBytes = 1408; # TODO: figure out where we lose those 12 bits (8 from pppoe maybe + ???)
        };

        # networkConfig = lib.mkIf (config.swarselsystems.isCloud && isServer) {
        #   IPv4Forwarding = true;
        #   IPv6Forwarding = true;
        # };

        address =
          if isServer then [
            globals.networks."${config.swarselsystems.server.netConfigPrefix}-wg".hosts.${config.node.name}.cidrv4
            globals.networks."${config.swarselsystems.server.netConfigPrefix}-wg".hosts.${config.node.name}.cidrv6
          ] else [
            globals.networks."${serverNetConfigPrefix}-wg".hosts.${config.node.name}.cidrv4
            globals.networks."${serverNetConfigPrefix}-wg".hosts.${config.node.name}.cidrv6
          ];
      };

      netdevs."50-${ifName}" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = ifName;
        };

        wireguardConfig = {
          ListenPort = lib.mkIf isServer servicePort;

          # ensure file is readable by `systemd-network` user
          PrivateKeyFile = config.sops.secrets.wireguard-private-key.path;

          # To automatically create routes for everything in AllowedIPs,
          # add RouteTable=main
          RouteTable = lib.mkIf isClient "main";

          # FirewallMark marks all packets send and received by wg0
          # with the number 42, which can be used to define policy rules on these packets.
          # FirewallMark = 42;
        };
        wireguardPeers = lib.optionals isClient [
          {
            PublicKey = builtins.readFile "${self}/secrets/public/wg/${serverName}.pub";
            PresharedKeyFile = config.sops.secrets."wireguard-${serverName}-${config.node.name}-presharedKey".path;
            Endpoint = "server.${serverName}.${globals.domains.main}:${toString servicePort}";
            # Access to the whole network is routed through our entry node.
            PersistentKeepalive = 25;
            AllowedIPs =
              let
                wgNetwork = globals.networks."${serverNetConfigPrefix}-wg";
              in
              (lib.optional (wgNetwork.cidrv4 != null) wgNetwork.cidrv4)
                ++ (lib.optional (wgNetwork.cidrv6 != null) wgNetwork.cidrv6);
          }
        ] ++ lib.optionals isServer (map
          (clientName: {
            PublicKey = builtins.readFile "${self}/secrets/public/wg/${clientName}.pub";
            PresharedKeyFile = config.sops.secrets."wireguard-${config.node.name}-${clientName}-presharedKey".path;
            # PersistentKeepalive = 25;
            AllowedIPs =
              let
                clientInWgNetwork = globals.networks."${config.swarselsystems.server.netConfigPrefix}-wg".hosts.${clientName};
              in
              (lib.optional (clientInWgNetwork.ipv4 != null) (lib.net.cidr.make 32 clientInWgNetwork.ipv4))
                ++ (lib.optional (clientInWgNetwork.ipv6 != null) (lib.net.cidr.make 128 clientInWgNetwork.ipv6));
          })
          peers);

      };
    };

    # networking = {
    #   wireguard = {
    #     enable = true;
    #     interfaces = {
    #       wg1 = {
    #         privateKeyFile = config.sops.secrets.wireguard-private-key.path;
    #         ips = [ "192.168.178.201/24" ];
    #         peers = [
    #           {
    #             publicKey = "PmeFInoEJcKx+7Kva4dNnjOEnJ8lbudSf1cbdo/tzgw=";
    #             presharedKeyFile = config.sops.secrets.wireguard-home-preshared-key.path;
    #             name = "moonside";
    #             persistentKeepalive = 25;
    #             # endpoint = "${config.repo.secrets.common.ipv4}:51820";
    #             endpoint = "${config.repo.secrets.common.wireguardEndpoint}";
    #             # allowedIPs = [
    #             #   "192.168.3.0/24"
    #             #   "192.168.1.0/24"
    #             # ];
    #             allowedIPs = [
    #               "192.168.178.0/24"
    #             ];
    #           }
    #         ];
    #       };
    #     };
    #   };
    # };


  };
}
