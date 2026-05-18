{ self, lib, config, dns, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "firefox-syncserver"; port = 5000; }) servicePort serviceName serviceUser serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  sopsFile = self + /secrets/general/invidious-companion.yaml;
in
{
  imports = [
    "${self}/modules/nixos/server/postgresql.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "firefox-syncserver" ];

    users.persistentIds = {
      firefox-syncserver = confLib.mkIds 949;
    };

    sops = {
      secrets = {
        firefox-syncserver-secret = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0400"; };
      };

      templates = {
        "firefox-syncserver.env" = {
          content = ''
            SYNC_MASTER_SECRET=${config.sops.placeholder."firefox-syncserver-secret"};
          '';
          owner = serviceUser;
          group = serviceGroup;
          mode = "0400";
        };
      };
    };

    topology.self.services.${serviceName} = {
      info = "https://${serviceDomain}";
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
      dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
    };

    services = {
      mysql.package = pkgs.mariadb;
      ${serviceName} = {
        enable = true;
        secrets = config.sops.templates."firefox-syncserver.env".path;

        singleNode = {
          enable = true;
          url = "https://${serviceDomain}";
          capacity = 1;
          hostname = serviceDomain; # we handle it ourselves however
          enableTLS = false; # we handle it ourselves
          enableNginx = false; # we handle it ourselves
        };

        settings = {
          host = "0.0.0.0";
          port = servicePort;
          tokenserver.enabled = true;
        };
      };
    };

    systemd.services.firefox-syncserver.serviceConfig.StateDirectory = "firefox-syncserver";

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = "/var/lib/private/firefox-syncserver"; }
    ];

    nodes = {
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };

}
