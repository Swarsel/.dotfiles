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
            root,
            config,
            lib,
            pkgs,
            confLib,
            dns,
            globals,
            nodes,
            ...
          }:
          let
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
              dmarcMailAddress
              homeServiceAddress
              homeWebProxy
              idmServer
              isHome
              nginxAccessRules
              webProxy
              ;
            baseDomain = globals.domains.main;
            roundcubeDB = config.services.roundcube.database;

            roundcubeDomain = config.repo.secrets.common.services.domains.roundcube;
            endpointAddress4 = globals.hosts.${config.node.name}.wanAddress4;
            endpointAddress6 = globals.hosts.${config.node.name}.wanAddress6;
            mtaStsDomain = "mta-sts.${baseDomain}";
            mtaStsPolicy = lib.concatMapStrings (line: "${line}\\r\\n") [
              "version: STSv1"
              "mode: enforce"
              "mx: ${serviceDomain}"
              "max_age: 86400"
            ];
          in
          {
            swarselsystems = {
              enabledServerModules = [ "mailserver" ];
              server.postgresql.rolePasswordFiles.${roundcubeDB.username} =
                config.sops.secrets."${roundcubeDB.username}-db-password".path;
            };
            topology.self.services = lib.mkMerge [
              (lib.genAttrs
                [
                  "postfix"
                  "dovecot"
                  "rspamd"
                  "clamav"
                  "roundcube"
                ]
                (service: {
                  icon = root "files/topology-images/${service}.png";
                  name = lib.swarselsystems.toCapitalized service;
                })
              )
              {
                postfix.info = "https://${serviceDomain}";
                roundcube.info = "https://${roundcubeDomain}";
              }
            ];
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
                _mta-sts.TXT = [
                  "v=STSv1; id=${builtins.substring 0 32 (builtins.hashString "sha256" mtaStsPolicy)}"
                ];
                "_smtp._tls".TXT = [ "v=TLSRPTv1; rua=mailto:${dmarcMailAddress}" ];
                mta-sts = dns.lib.combinators.host proxyAddress4 proxyAddress6; # name required by rfc 8461
              };
              monitoring = {
                http = confLib.mkHttpMonitoring {
                  inherit servicePort;
                  expectedBodyRegex = "Roundcube";
                  hostHeader = roundcubeDomain;
                  scheme = "https";
                  serviceName = "roundcube";
                };
                tcp = lib.mkMerge (
                  lib.mapAttrsToList
                    (
                      serviceName: args:
                      confLib.mkTcpMonitoring (
                        {
                          inherit serviceName;
                          expectedRegex = "^220 ";
                        }
                        // args
                      )
                    )
                    {
                      imaps = {
                        expectedRegex = "^\\* OK";
                        servicePort = 993;
                        tls = true;
                      };
                      smtp.servicePort = 25;
                      submission.servicePort = 587;
                      submissions = {
                        servicePort = 465;
                        tls = true;
                      };
                    }
                );
                systemd = lib.mkMerge (
                  map
                    (
                      serviceName:
                      confLib.mkSystemdMonitoring {
                        inherit serviceName;
                        unit = "${serviceName}.service";
                      }
                    )
                    [
                      "postfix-tlspol"
                      "redis-rspamd"
                      "rspamd"
                    ]
                  ++ [
                    (confLib.mkSystemdMonitoring {
                      oneshot = true;
                      serviceName = "rspamd-dmarc-reporter";
                      unit = "rspamd-dmarc-reporter.service";
                    })
                    (confLib.mkSystemdMonitoring {
                      oneshot = true;
                      serviceName = "dane-check";
                      unit = "dane-check.service";
                    })
                  ]
                );
              };
            };
            sops = {
              secrets =
                lib.genAttrs config.repo.secrets.local.mailserver.passwordSecrets (_: {
                  owner = serviceUser;
                })
                // {
                  "${roundcubeDB.username}-db-password" = {
                    group = roundcubeDB.username;
                    mode = "0440";
                    owner = config.systemd.services.postgresql.serviceConfig.User;
                    rekey.generator.script = "alnum";
                  };
                  mail-tls-key.owner = "acme";
                  parsedmarc-imap-hashed-password = {
                    owner = serviceUser;
                    rekey = {
                      generator = {
                        dependencies = [
                          nodes.${confLib.static.monitoringServer}.config.sops.secrets.parsedmarc-imap-password
                        ];
                        script = "bcrypt";
                      };
                      keyPrefix = confLib.static.sharedSecrets.parsedmarc;
                    };
                  };
                };
              templates.roundcube-setup-env.content = ''
                PGPASSWORD=${config.sops.placeholder."${roundcubeDB.username}-db-password"}
              '';
            };
            users.persistentIds = {
              knot-resolver = confLib.mkIds 963;
              postfix-tlspol = confLib.mkIds 962;
              redis-rspamd = confLib.mkIds 960;
              roundcube = confLib.mkIds 961;
            };
            services = {
              nginx.virtualHosts = {
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
                  useACMEHost = baseDomain;
                };
              };
              postfix.settings.main.smtpd_client_auth_rate_limit = 10;
              roundcube = {
                enable = true;
                configureNginx = true;
                extraConfig = ''
                  $config['db_dsnw'] = 'pgsql://${roundcubeDB.username}:' . rawurlencode(trim(file_get_contents('${
                    config.sops.secrets."${roundcubeDB.username}-db-password".path
                  }'))) . '@unix(/run/postgresql)/${roundcubeDB.dbname}';
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
              accounts = config.repo.secrets.local.mailserver.accounts // {
                ${dmarcMailAddress}.hashedPasswordFile = config.sops.secrets.parsedmarc-imap-hashed-password.path;
              };
              dmarcReporting.enable = true;
              domains = [ baseDomain ];
              enableImapSsl = true;
              enableSubmission = true;
              enableSubmissionSsl = true;
              fqdn = serviceDomain;
              indexDir = "${serviceDir}/indices";
              openFirewall = true;
              stateVersion = 3;
              x509.useACMEHost = baseDomain;
            };
            security.acme.certs.${baseDomain} = {
              extraLegoFlags = [
                "--private-key"
                config.sops.secrets.mail-tls-key.path
              ];
              extraLegoRenewFlags = [ "--reuse-key" ];
            };
            systemd = {
              services = {
                dane-check = {
                  script = ''
                    for port in 25 465 587 993; do
                      case "$port" in
                        25 | 587) starttls="-starttls smtp" ;;
                        *) starttls="" ;;
                      esac
                      served=$(${lib.getExe pkgs.openssl} s_client -connect "127.0.0.1:$port" -servername ${serviceDomain} $starttls </dev/null 2>/dev/null | ${lib.getExe pkgs.openssl} x509 -pubkey -noout | ${lib.getExe pkgs.openssl} pkey -pubin -outform DER | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d" " -f1)
                      published=$(${pkgs.knot-dns}/bin/kdig +short TLSA "_$port._tcp.${serviceDomain}" | ${pkgs.gnused}/bin/sed -E "s/^3 1 1 //; s/ //g" | ${pkgs.coreutils}/bin/tr "A-F" "a-f")
                      if [ -z "$served" ] || [ "$served" != "$published" ]; then
                        echo "TLSA record for port $port does not match the served certificate key"
                        exit 1
                      fi
                    done
                  '';
                  serviceConfig = {
                    DynamicUser = true;
                    Type = "oneshot";
                  };
                };
                roundcube-setup.serviceConfig.EnvironmentFile = config.sops.templates.roundcube-setup-env.path;
              };
              timers.dane-check = {
                timerConfig = {
                  OnCalendar = "daily";
                  Persistent = true;
                  RandomizedDelaySec = "1h";
                };
                wantedBy = [ "timers.target" ];
              };
            };
            nodes =
              let
                extraConfigLoc = ''
                  proxy_ssl_server_name on;
                  proxy_ssl_name ${roundcubeDomain};
                '';
              in
              lib.mkMerge [
                { ${idmServer} = confLib.mkKanidmOauth2ProxyAccess { serviceName = "roundcube"; }; }
                {
                  ${webProxy}.services.nginx.virtualHosts.${mtaStsDomain} = {
                    acmeRoot = null;
                    forceSSL = true;
                    locations."= /.well-known/mta-sts.txt".extraConfig = ''
                      default_type text/plain;
                      return 200 "${mtaStsPolicy}";
                    '';
                    useACMEHost = baseDomain;
                  };
                }
                {
                  ${webProxy}.services.nginx = confLib.genNginx {
                    inherit
                      extraConfigLoc
                      serviceAddress
                      serviceName
                      servicePort
                      ;
                    maxBody = 0;
                    oauth2 = true;
                    oauth2Groups = [ "roundcube_access" ];
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
