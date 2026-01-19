{ lib, pkgs, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "immich"; port = 3001; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy dnsServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselmodules.server = {
      postgresql = true;
    };

    users = {
      persistentIds = {
        immich = confLib.mkIds 989;
        redis-immich = confLib.mkIds 977;
      };
      users.${serviceUser} = {
        extraGroups = [ "video" "render" "users" ];
      };
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    # networking.firewall.allowedTCPPorts = [ servicePort ];
    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }
        { directory = "/var/cache/${serviceName}"; user = serviceUser; group = serviceGroup; }
        { directory = "/var/lib/redis-${serviceName}"; user = "redis-${serviceUser}"; group = "redis-${serviceGroup}"; }
      ];
    };

    services.${serviceName} = {
      enable = true;
      package = pkgs.immich;
      host = "0.0.0.0";
      port = servicePort;
      # openFirewall = true;
      mediaLocation = "/storage/Pictures/${serviceName}"; # dataDir
      environment = {
        IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://localhost:3003";
      };
    };

    nodes =
      let
        extraConfigLoc = ''
          proxy_http_version 1.1;
          proxy_set_header   Upgrade    $http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_redirect     off;

          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout       600s;
        '';
      in
      {
        ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
          "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
        };
        ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; };
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
      };

  };
}
