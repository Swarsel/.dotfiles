{
  flake.modules.generic.config-lib =
    {
      self,
      config,
      lib,
      globals,
      inputs,
      outputs,
      minimal,
      nixosConfig ? null,
      ...
    }:
    let
      domainDefault = service: config.repo.secrets.common.services.domains.${service};
      proxyDefault = config.swarselsystems.proxyHost;

      isWgProxyClient =
        globals.wireguard ? wgProxy && builtins.elem config.node.name globals.wireguard.wgProxy.clients;

      addressDefault =
        if config.swarselsystems.proxyHost != config.node.name then
          if isWgProxyClient then
            globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts.${config.node.name}.ipv4
          else
            globals.networks.${config.swarselsystems.server.netConfigName}.hosts.${config.node.name}.ipv4
        else
          "localhost";
    in
    {
      _module.args = {
        confLib = rec {
          getConfig = if nixosConfig == null then config else nixosConfig;

          gen =
            {
              name ? "n/a",
              user ? name,
              group ? user,
              dir ? null,
              port ? null,
              domain ? (domainDefault name),
              address ? addressDefault,
              proxy ? proxyDefault,
            }:
            rec {
              servicePort = port;
              serviceName = name;
              specificServiceName = "${name}-${config.node.name}";
              serviceUser = user;
              serviceGroup = group;
              serviceDomain = domain;
              baseDomain = lib.swarselsystems.getBaseDomain domain;
              subDomain = lib.swarselsystems.getSubDomain domain;
              serviceDir = dir;
              serviceAddress = address;
              serviceProxy = proxy;
              serviceNode = config.node.name;
              topologyContainerName = "${serviceNode}-${config.virtualisation.oci-containers.backend}-${name}";
              proxyAddress4 = globals.hosts.${proxy}.wanAddress4 or null;
              proxyAddress6 = globals.hosts.${proxy}.wanAddress6 or null;
            };

          static = rec {
            inherit (globals.hosts.${config.node.name}) isHome;
            inherit (globals.general)
              homeProxy
              routerServer
              webProxy
              dnsServer
              homeDnsServer
              homeWebProxy
              idmServer
              oauthServer
              monitoringServer
              ;
            webProxyIf = "${webProxy}-wgProxy";
            homeProxyIf = "home-wgHome";
            isProxied = config.node.name != webProxy;
            nginxAccessRules =
              let
                wgHomeNet = globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome";
              in
              ''
                allow ${globals.networks.home-lan.vlans.home.cidrv4};
                allow ${globals.networks.home-lan.vlans.home.cidrv6};
                allow ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv4};
                allow ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv6};
                allow ${wgHomeNet.cidrv4};
                allow ${wgHomeNet.cidrv6};
                deny all;
              '';
            scannerDropRules = ''
              location ~* "\.(php|aspx?|env|jsp|cgi|bak|sql|old)(\?|$|/)" {
                access_log off;
                return 444;
              }
              location ~* "(^|/)(\.git/|\.env|\.DS_Store|wp-admin|wp-login|wp-content|wp-includes|xmlrpc\.php|phpmy?admin|cgi-bin)" {
                access_log off;
                return 444;
              }
            '';
            wgProxyMembers = lib.optionals (globals.wireguard ? wgProxy) (
              globals.wireguard.wgProxy.clients ++ [ globals.wireguard.wgProxy.server ]
            );
            wgHomeMembers = lib.optionals (globals.wireguard ? wgHome) (
              globals.wireguard.wgHome.clients ++ [ globals.wireguard.wgHome.server ]
            );
            inWgProxy = builtins.elem config.node.name wgProxyMembers;
            inWgHome = builtins.elem config.node.name wgHomeMembers;
            homeServiceAddress =
              lib.optionalString inWgHome
                globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts.${config.node.name}.ipv4;

            wgProxyAccessRules =
              let
                wgProxyNet = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy";
                extraAllows = lib.concatMapStrings (
                  host:
                  let
                    cfg = globals.hosts.${host};
                  in
                  lib.optionalString (cfg.wanAddress4 != null) "allow ${cfg.wanAddress4};\n"
                  + lib.optionalString (cfg.wanAddress6 != null) "allow ${cfg.wanAddress6};\n"
                ) (lib.filter (h: !(builtins.elem h wgProxyMembers)) (lib.attrNames globals.hosts));
              in
              ''
                allow ${wgProxyNet.cidrv4};
                allow ${wgProxyNet.cidrv6};
              ''
              + extraAllows
              + ''
                deny all;
              '';
          };

          mkIds = id: {
            uid = id;
            gid = id;
          };

          mkDeviceMac =
            id:
            let
              mod = n: d: n - (n / d) * d;
              toHexByte =
                n:
                let
                  hex = "0123456789abcdef";
                  hi = n / 16;
                  lo = mod n 16;
                in
                builtins.substring hi 1 hex + builtins.substring lo 1 hex;

              max = 16777215; # 256^3 - 1

              b1 = id / (256 * 256);
              r1 = mod id (256 * 256);
              b2 = r1 / 256;
              b3 = mod r1 256;
            in
            if (id <= max) then
              (builtins.concatStringsSep ":" (
                map toHexByte [
                  b1
                  b2
                  b3
                ]
              ))
            else
              (throw "Device MAC ID too large (max is 16777215)");

          mkMicrovm =
            if config.swarselsystems.withMicroVMs then
              (
                guestName:
                {
                  eternorPaths ? [ ],
                  withZfs ? false,
                  ...
                }:
                {
                  ${guestName} = {
                    backend = "microvm";
                    autostart = true;
                    zfs = lib.mkIf withZfs (
                      {
                        # stateful config usually bind-mounted to /var/lib/ that should be backed up remotely
                        "/state" = {
                          pool = "Vault";
                          dataset = "guests/${guestName}/state";
                        };
                        # other stuff that should only reside on zfs, not backed up remotely
                        "/persist" = {
                          pool = "Vault";
                          dataset = "guests/${guestName}/persist";
                        };
                      }
                      // lib.optionalAttrs (eternorPaths != [ ]) (
                        lib.listToAttrs (
                          map
                            # data that is pulled in externally by services, some of which is backed up externally
                            (
                              eternorPath:
                              lib.nameValuePair "/storage/${eternorPath}" {
                                pool = "Vault";
                                dataset = "Eternor/${eternorPath}";
                              }
                            )
                            eternorPaths
                        )
                      )
                    );
                    modules = [
                      (config.node.configDir + /guests/${guestName}/default.nix)
                      {
                        node.secretsDir = config.node.configDir + /secrets/${guestName};
                        node.configDir = config.node.configDir + /guests/${guestName};
                        networking.nftables.firewall = {
                          zones.untrusted.interfaces = lib.mkIf (
                            lib.length config.guests.${guestName}.networking.links == 1
                          ) config.guests.${guestName}.networking.links;
                        };

                        fileSystems = {
                          "/persist".neededForBoot = true;
                        }
                        // lib.optionalAttrs withZfs {
                          "/state".neededForBoot = true;
                        };
                      }
                      self.modules.nixos.microvm-guest
                      self.modules.nixos.systemd-networkd-base
                    ];
                    microvm = {
                      system = config.node.arch;
                      baseMac = config.repo.secrets.local.networking.networks.lan.mac;
                      interfaces.vlan-services = {
                        mac = lib.mkForce "02:${lib.substring 3 5 config.guests.${guestName}.microvm.baseMac}:${
                          mkDeviceMac globals.networks.home-lan.vlans.services.hosts."${config.node.name}-${guestName}".id
                        }";

                      };
                    };
                    extraSpecialArgs = {
                      inherit (inputs.self) nodes;
                      inherit (inputs.self.pkgs.${config.node.arch}) lib;
                      inherit inputs outputs minimal;
                      inherit (inputs) self;
                      withHomeManager = false;
                      microVMParent = config.node.name;
                      globals = inputs.self.globals.${config.node.arch};
                    };
                  };
                }
              )
            else
              (_: {
                _ = { };
              });

          overrideTarget = target: {
            Unit = {
              PartOf = lib.mkForce [ target ];
              After = lib.mkForce [ target ];
            };
            Install.WantedBy = lib.mkForce [ target ];
          };

          mkKanidmOidcSystem =
            {
              serviceName,
              displayName ? lib.swarselsystems.toCapitalized serviceName,
              serviceDomain,
              originUrl,
              kanidmSopsFile,
              extraGroups ? [ ],
            }:
            {
              sops.secrets."kanidm-${serviceName}" = {
                sopsFile = kanidmSopsFile;
                owner = "kanidm";
                group = "kanidm";
                mode = "0440";
              };
              services.kanidm.provision = {
                groups = lib.genAttrs ([ "${serviceName}.access" ] ++ extraGroups) (_: { });
                systems.oauth2.${serviceName} = {
                  inherit displayName originUrl;
                  originLanding = "https://${serviceDomain}/";
                  basicSecretFile = config.sops.secrets."kanidm-${serviceName}".path;
                  scopeMaps."${serviceName}.access" = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  preferShortUsername = true;
                };
              };
            };

          mkServiceGlobal =
            {
              serviceName,
              serviceDomain,
              proxyAddress4,
              proxyAddress6,
              isHome,
              serviceAddress,
              homeServiceAddress,
              extra ? { },
            }:
            {
              ${serviceName} = {
                domain = serviceDomain;
                inherit
                  proxyAddress4
                  proxyAddress6
                  isHome
                  serviceAddress
                  ;
                homeServiceAddress = lib.mkIf isHome homeServiceAddress;
              }
              // extra;
            };

          mkTrayApplet =
            {
              description,
              execStart,
              extraService ? { },
            }:
            {
              Unit = {
                Description = description;
                Requires = [ "graphical-session.target" ];
                After = [
                  "graphical-session.target"
                  "tray.target"
                ];
                PartOf = [ "tray.target" ];
              };
              Install.WantedBy = [ "tray.target" ];
              Service = {
                ExecStart = execStart;
              }
              // extraService;
            };

          mkDualFirewallRules =
            {
              tcpPorts ? [ ],
              udpPorts ? [ ],
              forWebProxy ? true,
              forHomeProxy ? true,
            }:
            let
              rule = {
                allowedTCPPorts = lib.mkIf (tcpPorts != [ ]) tcpPorts;
                allowedUDPPorts = lib.mkIf (udpPorts != [ ]) udpPorts;
              };
            in
            {
              ${static.webProxyIf}.hosts = lib.mkIf (forWebProxy && static.isProxied) {
                ${config.node.name}.firewallRuleForNode.${static.webProxy} = rule;
              };
              ${static.homeProxyIf}.hosts = lib.mkIf (forHomeProxy && static.isHome) {
                ${config.node.name}.firewallRuleForNode.${static.homeWebProxy} = rule;
              };
            };

          mkGrafanaAlertRule =
            {
              uid,
              title,
              expr,
              op ? "lt",
              threshold ? 1,
              forDuration ? "5m",
              severity ? "critical",
              summary,
              datasourceUid ? "mimir",
              queryType ? null,
              noDataState ? "NoData",
            }:
            {
              inherit uid title noDataState;
              condition = "C";
              for = forDuration;
              execErrState = "Alerting";
              data = [
                {
                  refId = "A";
                  relativeTimeRange = {
                    from = 600;
                    to = 0;
                  };
                  inherit datasourceUid;
                  model = {
                    refId = "A";
                    inherit expr;
                    range = false;
                    instant = true;
                  }
                  // lib.optionalAttrs (queryType != null) { inherit queryType; };
                }
                {
                  refId = "C";
                  datasourceUid = "__expr__";
                  model = {
                    refId = "C";
                    type = "threshold";
                    expression = "A";
                    conditions = [
                      {
                        evaluator = {
                          type = op;
                          params = [ threshold ];
                        };
                      }
                    ];
                  };
                }
              ];
              annotations.summary = summary;
              labels.severity = severity;
            };

          mkAlloyPushUrl =
            {
              host,
              domain,
              port,
              path,
            }:
            let
              monitoringServer = globals.general.monitoringServer;
              isCentral = host == monitoringServer;
              isHomeHost = globals.hosts.${host}.isHome or false;
            in
            if isCentral then
              "http://127.0.0.1:${toString port}${path}"
            else if isHomeHost then
              "http://${
                globals.networks.home-lan.vlans.services.hosts.${monitoringServer}.ipv4
              }:${toString port}${path}"
            else
              "https://${domain}${path}";

          mkHttpMonitoring =
            {
              serviceName,
              servicePort,
              path ? "/",
              scheme ? "http",
              expectedBodyRegex ? null,
              expectedStatus ? null,
              hostHeader ? null,
              failIfBodyMatchesRegex ? null,
              alertFor ? null,
            }:
            {
              ${serviceName} = {
                url = "${scheme}://127.0.0.1:${toString servicePort}${path}";
                network = "local-${config.node.name}";
              }
              // lib.optionalAttrs (expectedBodyRegex != null) { inherit expectedBodyRegex; }
              // lib.optionalAttrs (expectedStatus != null) { inherit expectedStatus; }
              // lib.optionalAttrs (hostHeader != null) { inherit hostHeader; }
              // lib.optionalAttrs (failIfBodyMatchesRegex != null) { inherit failIfBodyMatchesRegex; }
              // lib.optionalAttrs (alertFor != null) { inherit alertFor; };
            };

          mkDnsRecord =
            {
              serviceName,
              proxyAddress4,
              proxyAddress6,
            }:
            let
              svc = globals.services.${serviceName};
            in
            {
              ${svc.baseDomain}.subdomainRecords.${svc.subDomain} =
                inputs.dns.lib.combinators.host proxyAddress4 proxyAddress6;
            };

          mkKanidmOauth2ProxyAccess =
            {
              serviceName,
              proxyGroup ? "${serviceName}_access",
            }:
            {
              services.kanidm.provision = {
                groups."${serviceName}.access" = { };
                systems.oauth2.oauth2-proxy = {
                  scopeMaps."${serviceName}.access" = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  claimMaps.groups.valuesByGroup."${serviceName}.access" = [ proxyGroup ];
                };
              };
            };

          genNginx =
            {
              serviceAddress,
              serviceName,
              serviceDomain,
              servicePort,
              protocol ? "http",
              maxBody ? (-1),
              maxBodyUnit ? "",
              noSslVerify ? false,
              proxyWebsockets ? false,
              oauth2 ? false,
              oauth2Groups ? [ ],
              extraConfig ? "",
              extraConfigLoc ? "",
            }:
            {
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
                  oauth2 = {
                    enable = lib.mkIf oauth2 true;
                    allowedGroups = lib.mkIf (oauth2Groups != [ ]) oauth2Groups;
                  };
                  locations = {
                    "/" = {
                      proxyPass = "${protocol}://${serviceName}";
                      proxyWebsockets = lib.mkIf proxyWebsockets true;
                      extraConfig =
                        lib.optionalString (maxBody != (-1)) ''
                          client_max_body_size ${builtins.toString maxBody}${maxBodyUnit};
                        ''
                        + extraConfigLoc;
                    };
                  };
                  extraConfig =
                    lib.optionalString noSslVerify ''
                      proxy_ssl_verify off;
                    ''
                    + extraConfig;
                };
              };
            };

        };
      };
    };
}
