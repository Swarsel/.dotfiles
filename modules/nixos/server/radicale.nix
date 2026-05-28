{ lib, config, confLib, ... }:
let
  inherit (confLib.gen { name = "radicale"; port = 8000; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) sopsFile;

  cfg = config.services.${serviceName};
in
{
  config = {
    swarselsystems.enabledServerModules = [ "radicale" ];

    sops = {
      secrets.radicale-user = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };

      templates =
        let
          inherit (config.repo.secrets.local.radicale) user1;
        in
        {
          "radicale-users" = {
            content = ''
              ${user1}:${config.sops.placeholder.radicale-user}
            '';
            owner = serviceUser;
            group = serviceGroup;
            mode = "0440";
          };
        };
    };

    users.persistentIds = {
      radicale = confLib.mkIds 982;
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
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
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/";
        expectedBodyRegex = "Radicale Web Interface";
        network = "local-${config.node.name}";
      };
    };

    services.${serviceName} = {
      enable = true;
      settings = {
        server = {
          hosts = [
            "0.0.0.0:${builtins.toString servicePort}"
            "[::]:${builtins.toString servicePort}"
          ];
        };
        auth =
          {
            type = "htpasswd";
            htpasswd_filename = config.sops.templates.radicale-users.path;
            htpasswd_encryption = "autodetect";
          };
        storage = {
          filesystem_folder = "/var/lib/radicale/collections";
        };
      };
      rights = {
        # all: match authenticated users only
        root = {
          user = ".+";
          collection = "";
          permissions = "R";
        };
        principal = {
          user = ".+";
          collection = "{user}";
          permissions = "RW";
        };
        calendars = {
          user = ".+";
          collection = "{user}/[^/]+";
          permissions = "rw";
        };
      };
    };

    systemd.tmpfiles.settings."10-radicale" = {
      "${cfg.settings.storage.filesystem_folder}" = {
        d = {
          group = serviceGroup;
          user = serviceUser;
          mode = "0750";
        };
      };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];


    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
      ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { inherit serviceName; };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 16; maxBodyUnit = "M"; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 16; maxBodyUnit = "M"; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
