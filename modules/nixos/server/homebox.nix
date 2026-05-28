{ self, lib, pkgs, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "homebox"; port = 7745; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  kanidmDomain = globals.services.kanidm.domain;
  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  imports = [
    "${self}/modules/nixos/server/postgresql.nix"
  ];

  config = {
    swarselsystems.enabledServerModules = [ "homebox" ];

    topology.self.services.${serviceName} = {
      name = "Homebox";
      info = "https://${serviceDomain}";
      icon = "${self}/files/topology-images/${serviceName}.png";
    };


    users.persistentIds = {
      homebox = confLib.mkIds 981;
    };

    sops = {
      secrets.kanidm-homebox = { sopsFile = kanidmSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      templates.homebox-oidc-env = {
        owner = serviceUser;
        content = ''
          HBOX_OIDC_CLIENT_SECRET=${config.sops.placeholder.kanidm-homebox}
        '';
      };
    };

    systemd.services.${serviceName}.serviceConfig.EnvironmentFile = config.sops.templates.homebox-oidc-env.path;

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
        url = "http://127.0.0.1:${toString servicePort}/api/v1/status";
        expectedBodyRegex = ''"health":\s*true'';
        network = "local-${config.node.name}";
      };
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
    };

    services.${serviceName} = {
      enable = true;
      package = pkgs.homebox;
      database.createLocally = true;
      settings = {
        HBOX_WEB_PORT = builtins.toString servicePort;
        HBOX_OPTIONS_ALLOW_REGISTRATION = "false";
        HBOX_OPTIONS_TRUST_PROXY = "true";
        HBOX_STORAGE_CONN_STRING = "file:///var/lib/homebox";
        HBOX_STORAGE_PREFIX_PATH = ".data";

        HBOX_OIDC_ENABLED = "true";
        HBOX_OIDC_ISSUER_URL = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
        HBOX_OIDC_CLIENT_ID = serviceName;
        HBOX_OIDC_BUTTON_TEXT = "Sign in with Kanidm";
      };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
      ${idmServer} = confLib.mkKanidmOidcSystem {
        inherit serviceName serviceDomain kanidmSopsFile;
        originUrl = "https://${serviceDomain}/api/v1/users/login/oidc/callback";
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
