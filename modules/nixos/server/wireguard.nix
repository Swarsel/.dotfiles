{ self, lib, config, confLib, globals, ... }:
let
  wgInterface = "wg0";
  inherit (confLib.gen { name = "wireguard"; port = 52829; user = "systemd-network"; group = "systemd-network"; }) servicePort serviceName serviceUser serviceGroup;

  inherit (config.swarselsystems) sopsFile;
  inherit (config.swarselsystems.server.wireguard) peers isClient isServer;
in
{
  options = {
    swarselmodules.${serviceName} = lib.mkEnableOption "enable ${serviceName} settings";
    swarselsystems.server.wireguard = {
      isServer = lib.mkEnableOption "set this as a wireguard server";
      peers = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          freeformType = lib.types.attrs;
          options = { };
        });
        default = [ ];
        description = "Wireguard peer submodules as expected by systemd.network.netdevs.<name>.wireguardPeers";
      };
    };

  };
  config = lib.mkIf config.swarselmodules.${serviceName} {

    sops = {
      secrets = {
        wireguard-private-key = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0600"; };
        wireguard-home-preshared-key = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0600"; };
      };
    };

    networking = {
      firewall.allowedUDPPorts = [ servicePort ];
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = "ens6";
        internalInterfaces = [ wgInterface ];
      };
    };

    systemd.network = {
      enable = true;

      networks."50-${wgInterface}" = {
        matchConfig.Name = wgInterface;

        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;
        };

        address = [
          "${globals.networks."${config.swarselsystems.server.netConfigPrefix}-wg".hosts.${config.node.name}.cidrv4}"
          "${globals.networks."${config.swarselsystems.server.netConfigPrefix}-wg".hosts.${config.node.name}.cidrv6}"
        ];
      };

      netdevs."50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = wgInterface;
        };

        wireguardConfig = {
          ListenPort = lib.mkIf isServer servicePort;

          # ensure file is readable by `systemd-network` user
          PrivateKeyFile = config.age.secrets.wg-key-vps.path;

          # To automatically create routes for everything in AllowedIPs,
          # add RouteTable=main
          # RouteTable = "main";

          # FirewallMark marks all packets send and received by wg0
          # with the number 42, which can be used to define policy rules on these packets.
          # FirewallMark = 42;
        };
        wireguardPeers = peers ++ lib.optionals isClient [
          {
            PublicKey = builtins.readFile "${self}/secrets/public/wg/${config.node.name}.pub";
            PresharedKeyFile = config.sops.secrets."${config.node.name}-presharedKey".path;
            Endpoint = "${globals.hosts.${config.node.name}.wanAddress4}:${toString servicePort}";
            # Access to the whole network is routed through our entry node.
            # AllowedIPs =
            #   (optional (networkCfg.cidrv4 != null) networkCfg.cidrv4)
            #     ++ (optional (networkCfg.cidrv6 != null) networkCfg.cidrv6);
          }
        ];
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
