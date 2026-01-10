{ self, lib, config, dns, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "microbin"; port = 8777; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy dnsServer homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;

  inherit (config.swarselsystems) sopsFile;

  cfg = config.services.${serviceName};
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    users = {
      groups.${serviceGroup} = { };

      users.${serviceUser} = {
        isSystemUser = true;
        group = serviceGroup;
      };
    };

    sops = {
      secrets = {
        microbin-admin-username = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        microbin-admin-password = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
        microbin-uploader-password = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };

      templates = {
        "microbin-env" = {
          content = ''
            MICROBIN_ADMIN_USERNAME="${config.sops.placeholder.microbin-admin-username}"
            MICROBIN_ADMIN_PASSWORD="${config.sops.placeholder.microbin-admin-password}"
            MICROBIN_UPLOADER_PASSWORD="${config.sops.placeholder.microbin-uploader-password}"
          '';
          owner = serviceUser;
          group = serviceGroup;
          mode = "0440";
        };
      };
    };

    topology.self.services.${serviceName} = {
      name = lib.swarselsystems.toCapitalized serviceName;
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
      passwordFile = config.sops.templates.microbin-env.path;
      dataDir = "/var/lib/microbin";
      settings = {
        MICROBIN_HIDE_LOGO = true;
        MICROBIN_PORT = servicePort;
        MICROBIN_EDITABLE = true;
        MICROBIN_HIDE_HEADER = true;
        MICROBIN_HIDE_FOOTER = true;
        MICROBIN_NO_LISTING = false;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_BIND = "0.0.0.0";
        MICROBIN_PRIVATE = true;
        MICROBIN_PUBLIC_PATH = "https://${serviceDomain}";
        MICROBIN_READONLY = true;
        MICROBIN_SHOW_READ_STATS = true;
        MICROBIN_TITLE = "~SwarselScratch~";
        MICROBIN_THREADS = 1;
        MICROBIN_GC_DAYS = 30;
        MICROBIN_ENABLE_BURN_AFTER = true;
        MICROBIN_QR = true;
        MICROBIN_ETERNAL_PASTA = true;
        MICROBIN_ENABLE_READONLY = true;
        MICROBIN_DEFAULT_EXPIRY = "1week";
        MICROBIN_NO_FILE_UPLOAD = false;
        MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB = 256;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 1024;
        MICROBIN_DISABLE_UPDATE_CHECKING = true;
        MICROBIN_DISABLE_TELEMETRY = true;
        MICROBIN_LIST_SERVER = false;
      };
    };

    systemd.services = {
      ${serviceName} = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = serviceUser;
          Group = serviceGroup;
        };
      };
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = cfg.dataDir; user = serviceUser; group = serviceGroup; mode = "0700"; }
    ];

    nodes = {
      ${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
        "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
      };
      ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 1; maxBodyUnit = "G"; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 1; maxBodyUnit = "G"; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
    };

  };

}
