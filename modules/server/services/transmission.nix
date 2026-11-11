{
  flake.modules.nixos.transmission =
    {
      self,
      root,
      config,
      lib,
      pkgs,
      confLib,
      globals,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "transmission";
          port = 9091;
        })
        serviceDomain
        servicePort
        ;
      inherit (confLib.static)
        homeProxyIf
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        ;

      piaNamespace = "pia";
      piaPortFile = "/run/pia/forwarded-port";
      piaTunnel = config.services.pia-netns.tunnels.${piaNamespace};

      arrPorts = {
        bazarr = 6767;
        lidarr = 8686;
        prowlarr = 9696;
        radarr = 7878;
        readarr = 8787;
        sonarr = 8989;
      };
      libraryApps = [
        "lidarr"
        "radarr"
        "readarr"
        "sonarr"
      ];
    in
    {
      imports = [
        self.modules.nixos.pia-netns
      ];
      config = {
        swarselsystems.enabledServerModules = [ "transmission" ];
        topology.self.services =
          lib.recursiveUpdate
            (lib.mapAttrs (name: _: { info = "https://${serviceDomain}/${name}"; }) arrPorts)
            {
              bazarr = {
                icon = root "files/topology-images/bazarr.png";
                name = "Bazarr";
              };
              readarr = {
                icon = root "files/topology-images/readarr.png";
                name = "Readarr";
              };
            };
        globals = {
          services.transmission = {
            inherit isHome;
            domain = serviceDomain;
          };
          monitoring = {
            http = lib.mkMerge (
              lib.mapAttrsToList (
                serviceName: servicePort:
                confLib.mkHttpMonitoring {
                  inherit serviceName servicePort;
                  expectedBodyRegex = "OK";
                  path = if serviceName == "bazarr" then "/bazarr/api/system/ping" else "/${serviceName}/ping";
                }
              ) arrPorts
            );
            systemd = lib.mkMerge [
              (confLib.mkSystemdMonitoring {
                oneshot = true;
                serviceName = "mam-dynamic-seedbox";
                unit = "mam-dynamic-seedbox.service";
              })
              (confLib.mkSystemdMonitoring {
                serviceName = "transmission";
                unit = "transmission.service";
              })
            ];
          };
          networks = lib.mkMerge [
            (confLib.mkDualFirewallRules {
              forWebProxy = false;
              tcpPorts = [ servicePort ] ++ lib.attrValues arrPorts;
            })
            (lib.optionalAttrs (globals.services ? seerr) {
              ${homeProxyIf}.hosts.${config.node.name}.firewallRuleForNode.${globals.services.seerr.extraConfig.node}.allowedTCPPorts =
                [
                  arrPorts.radarr
                  arrPorts.sonarr
                ];
            })
          ];
        };
        sops = {
          secrets = {
            mam-id = { };
            pia = { };
            transmission-rpc-password = { };
          };
          templates."transmission-credentials.json" = {
            content = ''
              {"rpc-username":"${config.swarselsystems.mainUser}","rpc-password":"${config.sops.placeholder.transmission-rpc-password}"}
            '';
            mode = "0400";
          };
        };
        users = {
          users =
            lib.mapAttrs (name: _: {
              extraGroups = [ "users" ];
              group = name;
              isSystemUser = true;
            }) arrPorts
            // {
              transmission.extraGroups = [ "users" ];
            };
          groups = lib.mapAttrs (_: _: { }) arrPorts;
          persistentIds = {
            bazarr = confLib.mkIds 932;
            prowlarr = confLib.mkIds 971;
            readarr = confLib.mkIds 970;
          };
        };
        services =
          lib.genAttrs libraryApps (name: {
            enable = true;
            dataDir = "/var/lib/${name}";
            group = name;
            openFirewall = true;
            settings.server.port = arrPorts.${name};
            user = name;
          })
          // {
            bazarr = {
              enable = true;
              group = "bazarr";
              openFirewall = true;
              settings.general = {
                base_url = "/bazarr";
                ip = "0.0.0.0";
                port = arrPorts.bazarr;
              };
              user = "bazarr";
            };
            pia-netns.tunnels.${piaNamespace} = {
              credentialsFile = config.sops.secrets.pia.path;
              forwards.transmission-rpc-forward = {
                port = servicePort;
                service = "transmission.service";
              };
              portForwarding = {
                enable = true;
                portFile = piaPortFile;
              };
              region = "sweden";
            };
            prowlarr = {
              enable = true;
              openFirewall = true;
              settings.server.port = arrPorts.prowlarr;
            };
            transmission = {
              enable = true;
              package = pkgs.transmission_3;
              credentialsFile = config.sops.templates."transmission-credentials.json".path;
              group = "users";
              openPeerPorts = false;
              openRPCPort = false;
              settings = {
                alt-speed-down = 12000;
                alt-speed-time-begin = 120;
                alt-speed-time-enabled = true;
                alt-speed-time-end = 480;
                alt-speed-up = 4000;
                cache-size-mb = 1024;
                dht-enabled = false;
                download-dir = "/storage/CHANGEME/seed";
                encryption = 2;
                peer-port-random-on-start = false;
                pex-enabled = false;
                port-forwarding-enabled = false;
                rpc-authentication-required = true;
                rpc-bind-address = "127.0.0.1";
                rpc-host-whitelist-enabled = false;
                rpc-port = servicePort;
                rpc-whitelist-enabled = false;
                speed-limit-down = 6000;
                speed-limit-down-enabled = true;
                speed-limit-up = 2000;
                speed-limit-up-enabled = true;
                umask = 7;
              };
            };
          };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories =
            map (name: {
              directory = "/var/lib/${name}";
              group = name;
              user = name;
            }) libraryApps
            ++ [
              {
                directory = "/var/lib/bazarr";
                group = "bazarr";
                mode = "0700";
                user = "bazarr";
              }
              {
                directory = "/var/lib/private/prowlarr";
                group = "prowlarr";
                user = "prowlarr";
              }
              {
                directory = "/var/lib/mam";
                group = "root";
                mode = "0700";
                user = "root";
              }
              {
                directory = "/var/lib/transmission";
                group = "users";
                user = "transmission";
              }
            ];
        };
        systemd = {
          services = {
            mam-dynamic-seedbox = {
              after = [ piaTunnel.unit ];
              partOf = [ piaTunnel.unit ];
              path = with pkgs; [
                curl
                iproute2
              ];
              requires = [ piaTunnel.unit ];
              script = ''
                install -d -m 0700 /var/lib/mam
                mam() {
                  ip netns exec ${piaNamespace} curl -sS --max-time 30 -c /var/lib/mam/cookies.txt -b "$1" "${config.repo.secrets.local.mamUrl}"
                }
                ok() {
                  grep -Eq '"Success":\s*true|Last change too recent' <<< "$1"
                }

                if [ -s /var/lib/mam/cookies.txt ] && ok "$(mam /var/lib/mam/cookies.txt)"; then
                  exit 0
                fi
                resp=$(mam "mam_id=$(cat ${config.sops.secrets.mam-id.path})")
                ok "$resp" || { echo "$resp" >&2; exit 1; }
              '';
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "5min";
                Type = "oneshot";
              };
              wantedBy = [ piaTunnel.unit ];
            };
            transmission = {
              after = [ piaTunnel.unit ];
              bindsTo = [ piaTunnel.unit ];
              partOf = [ piaTunnel.unit ];
              requires = [ piaTunnel.unit ];
              serviceConfig = {
                BindPaths = [
                  "/storage/Music"
                  "/storage/Videos"
                  "/storage/Books"
                  "/storage/Software"
                ];
                BindReadOnlyPaths = [ "/etc/netns/${piaNamespace}/resolv.conf:/etc/resolv.conf" ];
                NetworkNamespacePath = piaTunnel.netnsPath;
                TimeoutStartSec = "3600s";
              };
            };
            transmission-peer-port = {
              after = [
                "transmission.service"
                "transmission-rpc-forward.service"
              ];
              description = "Apply PIA-forwarded port to transmission";
              path = [ pkgs.transmission_3 ];
              script = ''
                if [ -s ${piaPortFile} ]; then
                  transmission-remote 127.0.0.1:${toString servicePort} \
                    -n "${config.swarselsystems.mainUser}:$(cat ${config.sops.secrets.transmission-rpc-password.path})" \
                    -p "$(cat ${piaPortFile})"
                fi
              '';
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "10s";
                Type = "oneshot";
              };
              wantedBy = [ "transmission.service" ];
              wants = [ "transmission-rpc-forward.service" ];
            };
          };
          paths.transmission-peer-port = {
            description = "Watch PIA forwarded-port file";
            pathConfig = {
              PathChanged = piaPortFile;
              Unit = "transmission-peer-port.service";
            };
            wantedBy = [ "multi-user.target" ];
          };
          timers.mam-dynamic-seedbox = {
            timerConfig = {
              OnBootSec = "10min";
              OnUnitActiveSec = "65min";
              Unit = "mam-dynamic-seedbox.service";
            };
            wantedBy = [ "timers.target" ];
          };
          tmpfiles.rules = [
            "d /storage/CHANGEME 0755 transmission users -"
            "d /storage/CHANGEME/seed 0755 transmission users -"
          ];
        };
        nodes.${homeWebProxy}.services.nginx = lib.mkIf isHome (
          let
            unlimitedBodyLocation = upstream: {
              extraConfig = ''
                client_max_body_size    0;
              '';
              proxyPass = "http://${upstream}";
            };
          in
          {
            upstreams = lib.mapAttrs (_: port: {
              servers."${homeServiceAddress}:${builtins.toString port}" = { };
            }) (arrPorts // { transmission = servicePort; });
            virtualHosts.${serviceDomain} = {
              acmeRoot = null;
              extraConfig = nginxAccessRules;
              forceSSL = true;
              locations =
                lib.mapAttrs' (name: _: lib.nameValuePair "/${name}" (unlimitedBodyLocation name)) (
                  lib.removeAttrs arrPorts [ "bazarr" ]
                )
                // {
                  "/" = unlimitedBodyLocation "transmission";
                  "/bazarr" = {
                    proxyPass = "http://bazarr";
                    proxyWebsockets = true;
                  };
                };
              useACMEHost = globals.domains.main;
            };
          }
        );
      };
    };
}
