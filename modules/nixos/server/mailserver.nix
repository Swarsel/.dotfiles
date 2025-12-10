{ lib, config, globals, dns, confLib, ... }:
let
  inherit (config.swarselsystems) sopsFile;
  inherit (confLib.gen { name = "mailserver"; dir = "/var/lib/dovecot"; user = "virtualMail"; group = "virtualMail"; port = 443; }) serviceName serviceDir servicePort serviceUser serviceGroup serviceDomain serviceProxy proxyAddress4 proxyAddress6;
  inherit (config.repo.secrets.local.mailserver) user1 alias1_1 alias1_2 alias1_3 alias1_4 user2 alias2_1 alias2_2 user3;
  baseDomain = globals.domains.main;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.stoicclub.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    globals.services.${serviceName} = {
      domain = serviceDomain;
      inherit proxyAddress4 proxyAddress6;
    };

    sops.secrets = {
      user1-hashed-pw = { inherit sopsFile; owner = serviceUser; };
      user2-hashed-pw = { inherit sopsFile; owner = serviceUser; };
      user3-hashed-pw = { inherit sopsFile; owner = serviceUser; };
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
      { directory = "/var/vmail"; user = serviceUser; group = serviceGroup; mode = "0770"; }
      { directory = "/var/sieve"; user = serviceUser; group = serviceGroup; mode = "0770"; }
      { directory = "/var/dkim"; user = "rspamd"; group = "rspamd"; mode = "0700"; }
      { directory = serviceDir; user = serviceUser; group = serviceGroup; mode = "0700"; }
      # { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0750"; }
      { directory = "/var/lib/rspamd"; user = "rspamd"; group = "rspamd"; mode = "0700"; }
      { directory = "/var/lib/roundcube"; user = "roundcube"; group = "roundcube"; mode = "0700"; }
      { directory = "/var/lib/redis-rspamd"; user = "redis-rspamd"; group = "redis-rspamd"; mode = "0700"; }
      { directory = "/var/lib/postfix"; user = "root"; group = "root"; mode = "0755"; }
      { directory = "/var/lib/knot-resolver"; user = "knot-resolver"; group = "knot-resolver"; mode = "0770"; }
    ];

    mailserver = {
      enable = true;
      stateVersion = 3;
      fqdn = serviceDomain;
      domains = [ baseDomain ];
      indexDir = "${serviceDir}/indices";
      openFirewall = true;
      certificateScheme = "acme";
      dmarcReporting.enable = true;

      loginAccounts = {
        "${user1}@${baseDomain}" = {
          hashedPasswordFile = config.sops.secrets.user1-hashed-pw.path;
          aliases = [
            "${alias1_1}@${baseDomain}"
            "${alias1_2}@${baseDomain}"
            "${alias1_3}@${baseDomain}"
            "${alias1_4}@${baseDomain}"
          ];
        };
        "${user2}@${baseDomain}" = {
          hashedPasswordFile = config.sops.secrets.user2-hashed-pw.path;
          aliases = [
            "${alias2_1}@${baseDomain}"
            "${alias2_2}@${baseDomain}"
          ];
          sendOnly = true;
        };
        "${user3}@${baseDomain}" = {
          hashedPasswordFile = config.sops.secrets.user3-hashed-pw.path;
          aliases = [
            "@${baseDomain}"
          ];
          catchAll = [
            baseDomain
          ];
        };
      };
    };

    services.roundcube = {
      enable = true;
      # this is the url of the vhost, not necessarily the same as the fqdn of
      # the mailserver
      hostName = serviceDomain;
      extraConfig = ''
        $config['imap_host'] = "ssl://${config.mailserver.fqdn}";
        $config['smtp_host'] = "ssl://${config.mailserver.fqdn}";
        $config['smtp_user'] = "%u";
        $config['smtp_pass'] = "%p";
      '';
      configureNginx = true;
    };

    # the rest of the ports are managed by snm
    networking.firewall.allowedTCPPorts = [ 80 servicePort ];

    nodes.${serviceProxy}.services.nginx = {
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/".recommendedSecurityHeaders = false;
            "~ ^/(SQL|bin|config|logs|temp|vendor)/".recommendedSecurityHeaders = false;
            "~ ^/(CHANGELOG.md|INSTALL|LICENSE|README.md|SECURITY.md|UPGRADING|composer.json|composer.lock)".recommendedSecurityHeaders = false;
            "~* \\.php(/|$)".recommendedSecurityHeaders = false;
          };
        };
      };
    };

  };
}
