{ self, lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "atuin"; port = 8888; }) servicePort serviceName serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
in
{
  imports = [
    "${self}/modules/nixos/server/postgresql.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "atuin" ];


    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/";
        expectedBodyRegex = ''"version":'';
        network = "local-${config.node.name}";
      };
    };

    services.${serviceName} = {
      enable = true;
      host = "0.0.0.0";
      port = servicePort;
      # openFirewall = true;
      openRegistration = false;
    };

    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };

}
