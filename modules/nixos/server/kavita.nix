{ self, lib, config, pkgs, globals, dns, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  inherit (confLib.gen { name = "kavita"; port = 8080; }) servicePort serviceName serviceUser serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy dnsServer homeProxyIf webProxyIf nginxAccessRules homeServiceAddress;
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {
    environment.systemPackages = with pkgs; [
      calibre
    ];


    users.users.${serviceUser} = {
      extraGroups = [ "users" ];
    };

    sops.secrets.kavita-token = { inherit sopsFile; owner = serviceUser; };

    # networking.firewall.allowedTCPPorts = [ servicePort ];
    topology.self.services.${serviceName} = {
      name = "Kavita";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

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

    services.${serviceName} = {
      enable = true;
      user = serviceUser;
      settings.Port = servicePort;
      tokenKeyFile = config.sops.secrets.kavita-token.path;
      dataDir = "/Vault/data/${serviceName}";
    };

    nodes = {
      ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
