{
  flake.modules.nixos.transmission =
    {
      self,
      pkgs,
      lib,
      config,
      globals,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "transmission";
          port = 9091;
        })
        servicePort
        serviceDomain
        ;
      inherit (confLib.static)
        isHome
        homeServiceAddress
        homeWebProxy
        nginxAccessRules
        ;
      inherit (config.swarselsystems) sopsFile;

      piaNamespace = "pia";
      piaNetnsPath = "/var/run/netns/${piaNamespace}";
      piaPortFile = "/run/pia/forwarded-port";

      lidarrUser = "lidarr";
      lidarrGroup = lidarrUser;
      lidarrPort = 8686;
      radarrUser = "radarr";
      radarrGroup = radarrUser;
      radarrPort = 7878;
      sonarrUser = "sonarr";
      sonarrGroup = sonarrUser;
      sonarrPort = 8989;
      readarrUser = "readarr";
      readarrGroup = readarrUser;
      readarrPort = 8787;
      prowlarrUser = "prowlarr";
      prowlarrGroup = prowlarrUser;
      prowlarrPort = 9696;
    in
    {
      imports = [
        self.modules.nixos.pia-netns
      ];

      config = {
        swarselsystems.enabledServerModules = [ "transmission" ];

        sops = {
          secrets = {
            pia = { inherit sopsFile; };
            mam-id = { inherit sopsFile; };
            transmission-rpc-password = { inherit sopsFile; };
          };
          templates."transmission-credentials.json" = {
            content = ''
              {"rpc-username":"${config.swarselsystems.mainUser}","rpc-password":"${config.sops.placeholder.transmission-rpc-password}"}
            '';
            mode = "0400";
          };
        };

        # this user/group section is probably unneeded
        users = {
          persistentIds = {
            prowlarr = confLib.mkIds 971;
            readarr = confLib.mkIds 970;
          };
          groups = {
            dockeruser = {
              gid = 1155;
            };
            "${radarrGroup}" = { };
            "${readarrGroup}" = { };
            "${sonarrGroup}" = { };
            "${lidarrGroup}" = { };
            "${prowlarrGroup}" = { };
          };
          users = {
            dockeruser = {
              isSystemUser = true;
              uid = 1155;
              group = "docker";
              extraGroups = [ "users" ];
            };
            "${radarrUser}" = {
              isSystemUser = true;
              group = radarrGroup;
              extraGroups = [ "users" ];
            };
            "${readarrUser}" = {
              isSystemUser = true;
              group = readarrGroup;
              extraGroups = [ "users" ];
            };
            "${sonarrUser}" = {
              isSystemUser = true;
              group = sonarrGroup;
              extraGroups = [ "users" ];
            };
            "${lidarrUser}" = {
              isSystemUser = true;
              group = lidarrGroup;
              extraGroups = [ "users" ];
            };
            "${prowlarrUser}" = {
              isSystemUser = true;
              group = prowlarrGroup;
              extraGroups = [ "users" ];
            };
            transmission.extraGroups = [ "users" ];
          };
        };

        virtualisation.docker.enable = true;
        environment.systemPackages = with pkgs; [
          docker
        ];

        topology.self.services = {
          radarr.info = "https://${serviceDomain}/radarr";
          readarr = {
            name = "Readarr";
            info = "https://${serviceDomain}/readarr";
            icon = "${self}/files/topology-images/readarr.png";
          };
          sonarr.info = "https://${serviceDomain}/sonarr";
          lidarr.info = "https://${serviceDomain}/lidarr";
          prowlarr.info = "https://${serviceDomain}/prowlarr";
        };

        globals = {
          networks = confLib.mkDualFirewallRules {
            forWebProxy = false;
            tcpPorts = [
              servicePort
              radarrPort
              readarrPort
              sonarrPort
              lidarrPort
              prowlarrPort
            ];
          };
          services.transmission = {
            domain = serviceDomain;
            inherit isHome;
          };
        };

        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/radarr";
              user = radarrUser;
              group = radarrGroup;
            }
            {
              directory = "/var/lib/readarr";
              user = readarrUser;
              group = readarrGroup;
            }
            {
              directory = "/var/lib/sonarr";
              user = sonarrUser;
              group = sonarrGroup;
            }
            {
              directory = "/var/lib/lidarr";
              user = lidarrUser;
              group = lidarrGroup;
            }
            {
              directory = "/var/lib/private/prowlarr";
              user = prowlarrUser;
              group = prowlarrGroup;
            }
            {
              directory = "/var/lib/mam";
              user = "root";
              group = "root";
              mode = "0700";
            }
            {
              directory = "/var/lib/transmission";
              user = "transmission";
              group = "transmission";
            }
          ];
        };

        services = {
          pia-netns = {
            enable = true;
            namespace = piaNamespace;
            region = "sweden";
            credentialsFile = config.sops.secrets.pia.path;
            dns = true;
            portForwarding = {
              enable = true;
              portFile = piaPortFile;
            };
          };
          transmission = {
            enable = true;
            openRPCPort = false;
            package = pkgs.transmission_3;
            openPeerPorts = false;
            credentialsFile = config.sops.templates."transmission-credentials.json".path;
            settings = {
              rpc-bind-address = "127.0.0.1";
              rpc-port = servicePort;
              rpc-whitelist-enabled = false;
              rpc-host-whitelist-enabled = false;
              peer-port-random-on-start = false;
              port-forwarding-enabled = false;
              rpc-authentication-required = true;
              umask = 7;

              download-dir = "/storage/CHANGEME/seed";
              encryption = 2;
              dht-enabled = false;
              pex-enabled = false;

              alt-speed-down = 12000;
              alt-speed-up = 4000;
              alt-speed-time-enabled = true;
              alt-speed-time-begin = 120;
              alt-speed-time-end = 480;

              speed-limit-down = 6000;
              speed-limit-down-enabled = true;
              speed-limit-up = 2000;
              speed-limit-up-enabled = true;

              cache-size-mb = 1024;
            };
          };
          radarr = {
            enable = true;
            user = radarrUser;
            group = radarrGroup;
            settings.server.port = radarrPort;
            openFirewall = true;
            dataDir = "/var/lib/radarr";
          };
          readarr = {
            enable = true;
            user = readarrUser;
            group = readarrGroup;
            settings.server.port = readarrPort;
            openFirewall = true;
            dataDir = "/var/lib/readarr";
          };
          sonarr = {
            enable = true;
            user = sonarrUser;
            group = sonarrGroup;
            settings.server.port = sonarrPort;
            openFirewall = true;
            dataDir = "/var/lib/sonarr";
          };
          lidarr = {
            enable = true;
            user = lidarrUser;
            group = lidarrGroup;
            settings.server.port = lidarrPort;
            openFirewall = true;
            dataDir = "/var/lib/lidarr";
          };
          prowlarr = {
            enable = true;
            settings.server.port = prowlarrPort;
            openFirewall = true;
          };
        };

        systemd = {
          tmpfiles.rules = [
            "d /storage/CHANGEME 0755 transmission transmission -"
            "d /storage/CHANGEME/seed 0755 transmission transmission -"
          ];

          paths.transmission-peer-port = {
            description = "Watch PIA forwarded-port file";
            wantedBy = [ "multi-user.target" ];
            pathConfig = {
              PathChanged = piaPortFile;
              Unit = "transmission-peer-port.service";
            };
          };

          timers.mam-dynamic-seedbox = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "10min";
              OnUnitActiveSec = "65min";
              Unit = "mam-dynamic-seedbox.service";
            };
          };

          services = {
            transmission = {
              after = [ "pia-netns.service" ];
              requires = [ "pia-netns.service" ];
              bindsTo = [ "pia-netns.service" ];
              partOf = [ "pia-netns.service" ];
              serviceConfig = {
                TimeoutStartSec = "3600s";
                NetworkNamespacePath = piaNetnsPath;
                BindReadOnlyPaths = [ "/etc/netns/${piaNamespace}/resolv.conf:/etc/resolv.conf" ];
                BindPaths = [
                  "/storage/Music"
                  "/storage/Videos"
                  "/storage/Books"
                  "/storage/Software"
                ];
              };
            };

            transmission-rpc-forward =
              let
                inner = pkgs.writeShellScript "transmission-rpc-into-netns" ''
                  exec ${pkgs.iproute2}/bin/ip netns exec ${piaNamespace} \
                    ${pkgs.socat}/bin/socat - TCP:127.0.0.1:${toString servicePort}
                '';
              in
              {
                description = "Forward host 127.0.0.1:${toString servicePort} into the PIA netns";
                after = [ "transmission.service" ];
                bindsTo = [ "transmission.service" ];
                partOf = [ "transmission.service" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = pkgs.writeShellScript "transmission-rpc-forward" ''
                    exec ${pkgs.socat}/bin/socat \
                      TCP-LISTEN:${toString servicePort},reuseaddr,fork \
                      EXEC:${inner}
                  '';
                  Restart = "on-failure";
                  RestartSec = "5s";
                };
              };

            transmission-peer-port = {
              description = "Apply PIA-forwarded port to transmission";
              after = [
                "transmission.service"
                "transmission-rpc-forward.service"
              ];
              wants = [ "transmission-rpc-forward.service" ];
              wantedBy = [ "transmission.service" ];
              path = with pkgs; [
                transmission_3
                coreutils
                jq
              ];
              serviceConfig = {
                Type = "oneshot";
                Restart = "on-failure";
                RestartSec = "10s";
              };
              script = ''
                CREDS=${config.sops.templates."transmission-credentials.json".path}
                USER=$(jq -r '."rpc-username"' "$CREDS")
                PASS=$(jq -r '."rpc-password"' "$CREDS")
                PORT=$(cat "${piaPortFile}" 2>/dev/null || true)
                [ -n "$PORT" ] || { echo "port file empty"; exit 0; }
                transmission-remote 127.0.0.1:${toString servicePort} -n "$USER:$PASS" -p "$PORT"
                echo "Set transmission peer port to $PORT"
              '';
            };

            mam-dynamic-seedbox = {
              after = [ "pia-netns.service" ];
              requires = [ "pia-netns.service" ];
              partOf = [ "pia-netns.service" ];
              wantedBy = [ "pia-netns.service" ];
              path = with pkgs; [
                curl
                iproute2
                coreutils
              ];
              serviceConfig = {
                Type = "oneshot";
                Restart = "on-failure";
                RestartSec = "5min";
              };
              script = ''
                COOKIES=/var/lib/mam/cookies.txt
                install -d -m 0700 /var/lib/mam

                URL="${config.repo.secrets.local.mamUrl}"
                EXEC="ip netns exec ${piaNamespace} curl -sS --max-time 30"

                is_ok() {
                  # "Success":true              → Completed / No change
                  # "Last change too recent"    → 429, IP is already current
                  echo "$1" | grep -Eq '"Success":\s*true|Last change too recent'
                }

                if [ -s "$COOKIES" ]; then
                  RESP=$($EXEC -c "$COOKIES" -b "$COOKIES" "$URL" || true)
                else
                  RESP=""
                fi

                if is_ok "$RESP"; then
                  echo "MAM: $RESP"
                  exit 0
                fi

                echo "MAM: cookie-jar call needs re-init (resp: $RESP)"
                MAM_ID=$(cat "${config.sops.secrets.mam-id.path}")
                RESP=$($EXEC -c "$COOKIES" -b "mam_id=$MAM_ID" "$URL" || true)
                echo "MAM: $RESP"
                is_ok "$RESP"
              '';
            };

          };
        };

        nodes = {
          ${homeWebProxy}.services.nginx = {
            upstreams = {
              transmission = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString servicePort}" = { };
                };
              };
              radarr = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString radarrPort}" = { };
                };
              };
              readarr = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString readarrPort}" = { };
                };
              };
              sonarr = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString sonarrPort}" = { };
                };
              };
              lidarr = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString lidarrPort}" = { };
                };
              };
              prowlarr = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString prowlarrPort}" = { };
                };
              };
            };
            virtualHosts = {
              "${serviceDomain}" = {
                useACMEHost = globals.domains.main;
                forceSSL = true;
                acmeRoot = null;
                extraConfig = nginxAccessRules;
                locations = {
                  "/" = {
                    proxyPass = "http://transmission";
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                  };
                  "/radarr" = {
                    proxyPass = "http://radarr";
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                  };
                  "/readarr" = {
                    proxyPass = "http://readarr";
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                  };
                  "/sonarr" = {
                    proxyPass = "http://sonarr";
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                  };
                  "/lidarr" = {
                    proxyPass = "http://lidarr";
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                  };
                  "/prowlarr" = {
                    proxyPass = "http://prowlarr";
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                  };
                };
              };
            };
          };
        };
      };
    }

  ;
}
