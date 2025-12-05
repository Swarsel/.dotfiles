{ lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "radicale"; port = 8000; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress serviceProxy proxyAddress4 proxyAddress6;
  # sopsFile = config.node.secretsDir + "/secrets2.yaml";
  inherit (config.swarselsystems) sopsFile;

  cfg = config.services.${serviceName};
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

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

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
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
          filesystem_folder = "/Vault/data/radicale/collections";
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

    networking.firewall.allowedTCPPorts = [ servicePort ];

    nodes.${serviceProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          useACMEHost = globals.domains.main;

          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 16M;
              '';
            };
          };
        };
      };
    };

  };

}
