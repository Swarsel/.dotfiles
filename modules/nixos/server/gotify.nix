{ self, lib, config, confLib, ... }:
let
  inherit (confLib.gen {
    name = "gotify";
    port = 8080;
    dir = "/var/lib/private/gotify-server";
  }) servicePort serviceName serviceDir serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy homeServiceAddress nginxAccessRules;
in
{
  imports = [
    "${self}/modules/nixos/server/postgresql.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ serviceName ];

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; extra.extraConfig.port = servicePort; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/health"; expectedBodyRegex = "ok|green"; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = serviceDir; mode = "0700"; }];
    };

    services.postgresql = {
      ensureDatabases = [ "gotify-server" ];
      ensureUsers = [{
        name = "gotify-server";
        ensureDBOwnership = true;
      }];
    };

    services.${serviceName} = {
      enable = true;
      environment = {
        GOTIFY_SERVER_PORT = servicePort;
        GOTIFY_SERVER_LISTENADDR = "0.0.0.0";
        GOTIFY_DATABASE_DIALECT = "postgres";
        GOTIFY_DATABASE_CONNECTION = "host=/run/postgresql user=gotify-server dbname=gotify-server sslmode=disable";
        GOTIFY_PASSSTRENGTH = 12;
        GOTIFY_UPLOADEDIMAGESDIR = "${serviceDir}/images";
        GOTIFY_PLUGINSDIR = "${serviceDir}/plugins";
      };
    };

    systemd.services.gotify-server.serviceConfig.RestartSec = lib.mkForce "60";

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx {
        inherit serviceAddress servicePort serviceDomain serviceName;
        proxyWebsockets = true;
        maxBody = 50;
        maxBodyUnit = "M";
        # extraConfig = wgProxyAccessRules;
      };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx {
        inherit servicePort serviceDomain serviceName;
        serviceAddress = homeServiceAddress;
        proxyWebsockets = true;
        maxBody = 50;
        maxBodyUnit = "M";
        extraConfig = nginxAccessRules;
      });
    };
  };
}
