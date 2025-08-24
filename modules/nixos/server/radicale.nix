{ self, lib, config, globals, ... }:
let
  sopsFile = self + /secrets/winters/secrets2.yaml;

  servicePort = 8000;
  serviceName = "radicale";
  serviceUser = "radicale";
  serviceGroup = serviceUser;
  serviceDomain = config.repo.secrets.common.services.domains.${serviceName};
  serviceAddress = globals.hosts.winters.ipv4;

  cfg = config.services.${serviceName};
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

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
    globals.services.${serviceName}.domain = serviceDomain;

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

    systemd.tmpfiles.rules = [
      "d ${cfg.settings.storage.filesystem_folder} 0750 ${serviceUser} ${serviceGroup} - -"
    ];

    networking.firewall.allowedTCPPorts = [ servicePort ];

    nodes.moonside.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
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
