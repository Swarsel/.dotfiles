{ self, lib, pkgs, config, globals, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;

  inherit (confLib.gen { name = "kavita"; port = 8080; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome webProxy homeWebProxy idmServer nginxAccessRules homeServiceAddress;

  kanidmDomain = globals.services.kanidm.domain;
  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  config = {
    swarselsystems.enabledServerModules = [ "kavita" ];

    users = {
      persistentIds.kavita = confLib.mkIds 995;
      users.${serviceUser} = {
        extraGroups = [ "users" ];
      };
    };


    sops.secrets = {
      kavita-token = { inherit sopsFile; owner = serviceUser; };
      kanidm-kavita = { sopsFile = kanidmSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];
    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [{ directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }];
    };

    globals = {
      networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; expectedBodyRegex = "<title>Kavita</title>"; };
      dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
    };

    services.${serviceName} = {
      enable = true;
      user = serviceUser;
      settings = {
        Port = servicePort;
        OpenIdConnectSettings = {
          Authority = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
          ClientId = serviceName;
          Secret = "@OIDC_SECRET@";
          CustomScopes = [ ];
        };
      };
      tokenKeyFile = config.sops.secrets.kavita-token.path;
      dataDir = "/var/lib/${serviceName}";
    };

    systemd.services.${serviceName} = {
      serviceConfig.LoadCredential = [ "oidc-secret:${config.sops.secrets.kanidm-kavita.path}" ];
      preStart = lib.mkAfter ''
        ${pkgs.replace-secret}/bin/replace-secret '@OIDC_SECRET@' \
          "''${CREDENTIALS_DIRECTORY}/oidc-secret" \
          '/var/lib/${serviceName}/config/appsettings.json'
      '';
    };


    nodes = {
      ${idmServer} = confLib.mkKanidmOidcSystem {
        inherit serviceName serviceDomain kanidmSopsFile;
        originUrl = "https://${serviceDomain}/signin-oidc";
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };
}
