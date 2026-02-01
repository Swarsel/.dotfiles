{ self, lib, config, dns, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "shlink"; port = 8081; dir = "/var/lib/shlink"; }) servicePort serviceName serviceDomain serviceDir serviceAddress proxyAddress4 proxyAddress6 topologyContainerName;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy dnsServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  containerRev = "sha256:1a697baca56ab8821783e0ce53eb4fb22e51bb66749ec50581adc0cb6d031d7a";

  inherit (config.swarselsystems) sopsFile;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    swarselmodules.server = {
      podman = true;
    };

    sops = {
      secrets = {
        shlink-api = { inherit sopsFile; };
      };

      templates = {
        "shlink-env" = {
          content = ''
            INITIAL_API_KEY=${config.sops.placeholder.shlink-api}
          '';
        };
      };
    };

    topology.nodes.${topologyContainerName}.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };

    virtualisation.oci-containers.containers.${serviceName} = {
      image = "shlinkio/shlink@${containerRev}";
      environment = {
        "DEFAULT_DOMAIN" = serviceDomain;
        "PORT" = "${builtins.toString servicePort}";
        "USE_HTTPS" = "false";
        "DEFAULT_SHORT_CODES_LENGTH" = "4";
        "WEB_WORKER_NUM" = "1";
        "TASK_WORKER_NUM" = "1";
      };
      environmentFiles = [
        config.sops.templates.shlink-env.path
      ];
      ports = [ "${builtins.toString servicePort}:${builtins.toString servicePort}" ];
      volumes = [
        "${serviceDir}/data:/etc/shlink/data"
      ];
    };

    systemd.tmpfiles.settings."11-shlink" = builtins.listToAttrs (
      map
        (path: {
          name = "${serviceDir}/${path}";
          value = {
            d = {
              group = "root";
              user = "1001";
              mode = "0750";
            };
          };
        }) [
        "data"
        "data/cache"
        "data/locks"
        "data/log"
        "data/proxies"
      ]
    );

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = serviceDir; }
      { directory = "/var/lib/containers"; }
    ];

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

    nodes = {
      ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
