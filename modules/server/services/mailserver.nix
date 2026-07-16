{
  flake-file.inputs.simple-nixos-mailserver = {
    inputs = {
      git-hooks.follows = "pre-commit-hooks";
      nixpkgs.follows = "nixpkgs";
    };
    url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";
  };

  flake.modules.nixos.mailserver =
    {
      self,
      inputs,
      lib,
      ...
    }:
    {
      imports = lib.optionals (inputs ? simple-nixos-mailserver) [
        self.modules.nixos.postgresql
        self.modules.nixos.nginx
        self.modules.nixos.acme
        inputs.simple-nixos-mailserver.nixosModules.default
        (
          {
            self,
            config,
            lib,
            confLib,
            dns,
            globals,
            ...
          }:
          let
            inherit (config.swarselsystems) sopsFile;
            inherit
              (confLib.gen {
                dir = "/var/lib/dovecot";
                group = "virtualMail";
                name = "mailserver";
                port = 443;
                user = "virtualMail";
              })
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDir
              serviceDomain
              serviceGroup
              serviceName
              servicePort
              serviceUser
              ;
            inherit (confLib.static)
              homeServiceAddress
              homeWebProxy
              isHome
              nginxAccessRules
              webProxy
              ;
            inherit (config.repo.secrets.local.mailserver)
              alias1_1
              alias1_2
              alias1_3
              alias1_4
              alias2_1
              alias2_2
              alias2_3
              alias2_4
              user1
              user2
              user3
              ;
            baseDomain = globals.domains.main;

            roundcubeDomain = config.repo.secrets.common.services.domains.roundcube;
            endpointAddress4 = globals.hosts.${config.node.name}.wanAddress4 or null;
            endpointAddress6 = globals.hosts.${config.node.name}.wanAddress6 or null;
          in
          {
            swarselsystems.enabledServerModules = [ "mailserver" ];
            topology.self.services = lib.listToAttrs (
              map
                (
                  service:
                  lib.nameValuePair "${service}" {
                    icon = "${self}/files/topology-images/${service}.png";
                    info = lib.mkIf (service == "postfix" || service == "roundcube") (
                      if service == "postfix" then "https://${serviceDomain}" else "https://${roundcubeDomain}"
                    );
                    name = lib.swarselsystems.toCapitalized service;
                  }
                )
                [
                  "postfix"
                  "dovecot"
                  "rspamd"
                  "clamav"
                  "roundcube"
                ]
            );
            globals = {
              services = {
                ${serviceName} = {
                  domain = serviceDomain;
                  proxyAddress4 = endpointAddress4;
                  proxyAddress6 = endpointAddress6;
                };
                roundcube = {
                  inherit
                    isHome
                    proxyAddress4
                    proxyAddress6
                    serviceAddress
                    ;
                  domain = roundcubeDomain;
                  homeServiceAddress = lib.mkIf isHome homeServiceAddress;
                };
              };
              dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
                "${globals.services.${serviceName}.subDomain}" =
                  dns.lib.combinators.host endpointAddress4 endpointAddress6;
                "${globals.services.roundcube.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
              };
            };
            sops.secrets = {
              user1-hashed-pw = {
                inherit sopsFile;
                owner = serviceUser;
              };
              user2-hashed-pw = {
                inherit sopsFile;
                owner = serviceUser;
              };
              user3-hashed-pw = {
                inherit sopsFile;
                owner = serviceUser;
              };
            };
            users = {
              persistentIds = {
                knot-resolver = confLib.mkIds 963;
                postfix-tlspol = confLib.mkIds 962;
                redis-rspamd = confLib.mkIds 960;
                roundcube = confLib.mkIds 961;
              };
            };
            services = {
              nginx = {
                virtualHosts = {
                  "${roundcubeDomain}" = {
                    acmeRoot = null;
                    enableACME = false;
                    forceSSL = true;
                    locations = {
                      "/".recommendedSecurityHeaders = false;
                      "~ ^/(CHANGELOG.md|INSTALL|LICENSE|README.md|SECURITY.md|UPGRADING|composer.json|composer.lock)".recommendedSecurityHeaders =
                        false;
                      "~ ^/(SQL|bin|config|logs|temp|vendor)/".recommendedSecurityHeaders = false;
                      "~* \\.php(/|$)".recommendedSecurityHeaders = false;
                    };
                    useACMEHost = globals.domains.main;
                  };
                };
              };
              roundcube = {
                enable = true;
                configureNginx = true;
                extraConfig = ''
                  $config['imap_host'] = "ssl://${config.mailserver.fqdn}";
                  $config['smtp_host'] = "ssl://${config.mailserver.fqdn}";
                  $config['smtp_user'] = "%u";
                  $config['smtp_pass'] = "%p";
                '';
                # this is the url of the vhost, not necessarily the same as the fqdn of
                # the mailserver
                hostName = roundcubeDomain;
              };
            };
            environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
              {
                directory = "/var/vmail";
                group = serviceGroup;
                mode = "0770";
                user = serviceUser;
              }
              {
                directory = "/var/sieve";
                group = serviceGroup;
                mode = "0770";
                user = serviceUser;
              }
              {
                directory = "/var/dkim";
                group = "rspamd";
                mode = "0700";
                user = "rspamd";
              }
              {
                directory = serviceDir;
                group = serviceGroup;
                mode = "0700";
                user = serviceUser;
              }
              # { directory = "/var/lib/postgresql"; user = "postgres"; group = "postgres"; mode = "0750"; }
              {
                directory = "/var/lib/rspamd";
                group = "rspamd";
                mode = "0700";
                user = "rspamd";
              }
              {
                directory = "/var/lib/roundcube";
                group = "roundcube";
                mode = "0700";
                user = "roundcube";
              }
              {
                directory = "/var/lib/redis-rspamd";
                group = "redis-rspamd";
                mode = "0700";
                user = "redis-rspamd";
              }
              {
                directory = "/var/lib/postfix";
                group = "root";
                mode = "0755";
                user = "root";
              }
              {
                directory = "/var/lib/knot-resolver";
                group = "knot-resolver";
                mode = "0770";
                user = "knot-resolver";
              }
            ];
            mailserver = {
              enable = true;
              accounts = {
                "${user1}@${baseDomain}" = {
                  aliases = [
                    "${alias1_1}@${baseDomain}"
                    "${alias1_2}@${baseDomain}"
                    "${alias1_3}@${baseDomain}"
                    "${alias1_4}@${baseDomain}"
                  ];
                  hashedPasswordFile = config.sops.secrets.user1-hashed-pw.path;
                };
                "${user2}@${baseDomain}" = {
                  aliases = [
                    "${alias2_1}@${baseDomain}"
                    "${alias2_2}@${baseDomain}"
                    "${alias2_3}@${baseDomain}"
                    "${alias2_4}@${baseDomain}"
                  ];
                  hashedPasswordFile = config.sops.secrets.user2-hashed-pw.path;
                  sendOnly = true;
                };
                "${user3}@${baseDomain}" = {
                  aliases = [
                    "@${baseDomain}"
                  ];
                  catchAll = [
                    baseDomain
                  ];
                  hashedPasswordFile = config.sops.secrets.user3-hashed-pw.path;
                };
              };
              # certificateScheme = "acme";
              dmarcReporting.enable = true;
              domains = [ baseDomain ];
              enableImapSsl = true;
              enableSubmission = true;
              enableSubmissionSsl = true;
              fqdn = serviceDomain;
              indexDir = "${serviceDir}/indices";
              openFirewall = true;
              stateVersion = 3;
              x509.useACMEHost = globals.domains.main;
            };
            # the rest of the ports are managed by snm
            networking.firewall.allowedTCPPorts = [
              80
              443
            ];
            nodes =
              let
                extraConfigLoc = ''
                  proxy_ssl_server_name on;
                  proxy_ssl_name ${roundcubeDomain};
                '';
              in
              lib.mkMerge [
                {
                  ${webProxy}.services.nginx = confLib.genNginx {
                    inherit
                      extraConfigLoc
                      serviceAddress
                      serviceName
                      servicePort
                      ;
                    maxBody = 0;
                    protocol = "https";
                    serviceDomain = roundcubeDomain;
                  };
                }
                {
                  ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                    confLib.genNginx {
                      inherit extraConfigLoc serviceName servicePort;
                      extraConfig = nginxAccessRules;
                      maxBody = 0;
                      protocol = "https";
                      serviceAddress = homeServiceAddress;
                      serviceDomain = roundcubeDomain;
                    }
                  );
                }
              ];
          }
        )
      ];
    };
}
