{
  flake.modules.nixos.transmission =
    {
      self,
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
        homeServiceAddress
        homeWebProxy
        isHome
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
        topology.self.services = {
          lidarr.info = "https://${serviceDomain}/lidarr";
          prowlarr.info = "https://${serviceDomain}/prowlarr";
          radarr.info = "https://${serviceDomain}/radarr";
          readarr = {
            icon = "${self}/files/topology-images/readarr.png";
            info = "https://${serviceDomain}/readarr";
            name = "Readarr";
          };
          sonarr.info = "https://${serviceDomain}/sonarr";
        };
        globals = {
          services.transmission = {
            inherit isHome;
            domain = serviceDomain;
          };
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
        };
        sops = {
          secrets = {
            mam-id = { inherit sopsFile; };
            pia = { inherit sopsFile; };
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
          users = {
            "${lidarrUser}" = {
              extraGroups = [ "users" ];
              group = lidarrGroup;
              isSystemUser = true;
            };
            "${prowlarrUser}" = {
              extraGroups = [ "users" ];
              group = prowlarrGroup;
              isSystemUser = true;
            };
            "${radarrUser}" = {
              extraGroups = [ "users" ];
              group = radarrGroup;
              isSystemUser = true;
            };
            "${readarrUser}" = {
              extraGroups = [ "users" ];
              group = readarrGroup;
              isSystemUser = true;
            };
            "${sonarrUser}" = {
              extraGroups = [ "users" ];
              group = sonarrGroup;
              isSystemUser = true;
            };
            dockeruser = {
              extraGroups = [ "users" ];
              group = "docker";
              isSystemUser = true;
              uid = 1155;
            };
            transmission.extraGroups = [ "users" ];
          };
          groups = {
            "${lidarrGroup}" = { };
            "${prowlarrGroup}" = { };
            "${radarrGroup}" = { };
            "${readarrGroup}" = { };
            "${sonarrGroup}" = { };
            dockeruser = {
              gid = 1155;
            };
          };
          persistentIds = {
            prowlarr = confLib.mkIds 971;
            readarr = confLib.mkIds 970;
          };
        };
        services = {
          lidarr = {
            enable = true;
            dataDir = "/var/lib/lidarr";
            group = lidarrGroup;
            openFirewall = true;
            settings.server.port = lidarrPort;
            user = lidarrUser;
          };
          pia-netns = {
            enable = true;
            credentialsFile = config.sops.secrets.pia.path;
            dns = true;
            namespace = piaNamespace;
            portForwarding = {
              enable = true;
              portFile = piaPortFile;
            };
            region = "sweden";
          };
          prowlarr = {
            enable = true;
            openFirewall = true;
            settings.server.port = prowlarrPort;
          };
          radarr = {
            enable = true;
            dataDir = "/var/lib/radarr";
            group = radarrGroup;
            openFirewall = true;
            settings.server.port = radarrPort;
            user = radarrUser;
          };
          readarr = {
            enable = true;
            dataDir = "/var/lib/readarr";
            group = readarrGroup;
            openFirewall = true;
            settings.server.port = readarrPort;
            user = readarrUser;
          };
          sonarr = {
            enable = true;
            dataDir = "/var/lib/sonarr";
            group = sonarrGroup;
            openFirewall = true;
            settings.server.port = sonarrPort;
            user = sonarrUser;
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
        environment = {
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/radarr";
                group = radarrGroup;
                user = radarrUser;
              }
              {
                directory = "/var/lib/readarr";
                group = readarrGroup;
                user = readarrUser;
              }
              {
                directory = "/var/lib/sonarr";
                group = sonarrGroup;
                user = sonarrUser;
              }
              {
                directory = "/var/lib/lidarr";
                group = lidarrGroup;
                user = lidarrUser;
              }
              {
                directory = "/var/lib/private/prowlarr";
                group = prowlarrGroup;
                user = prowlarrUser;
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
          systemPackages = with pkgs; [
            docker
          ];
        };
        virtualisation.docker.enable = true;
        systemd = {
          services = {
            mam-dynamic-seedbox = {
              after = [ "pia-netns.service" ];
              partOf = [ "pia-netns.service" ];
              path = with pkgs; [
                curl
                iproute2
                coreutils
              ];
              requires = [ "pia-netns.service" ];
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
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "5min";
                Type = "oneshot";
              };
              wantedBy = [ "pia-netns.service" ];
            };
            transmission = {
              after = [ "pia-netns.service" ];
              bindsTo = [ "pia-netns.service" ];
              partOf = [ "pia-netns.service" ];
              requires = [ "pia-netns.service" ];
              serviceConfig = {
                BindPaths = [
                  "/storage/Music"
                  "/storage/Videos"
                  "/storage/Books"
                  "/storage/Software"
                ];
                BindReadOnlyPaths = [ "/etc/netns/${piaNamespace}/resolv.conf:/etc/resolv.conf" ];
                NetworkNamespacePath = piaNetnsPath;
                TimeoutStartSec = "3600s";
              };
            };
            transmission-peer-port = {
              after = [
                "transmission.service"
                "transmission-rpc-forward.service"
              ];
              description = "Apply PIA-forwarded port to transmission";
              path = with pkgs; [
                transmission_3
                coreutils
                jq
              ];
              script = ''
                CREDS=${config.sops.templates."transmission-credentials.json".path}
                USER=$(jq -r '."rpc-username"' "$CREDS")
                PASS=$(jq -r '."rpc-password"' "$CREDS")
                PORT=$(cat "${piaPortFile}" 2>/dev/null || true)
                [ -n "$PORT" ] || { echo "port file empty"; exit 0; }
                transmission-remote 127.0.0.1:${toString servicePort} -n "$USER:$PASS" -p "$PORT"
                echo "Set transmission peer port to $PORT"
              '';
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "10s";
                Type = "oneshot";
              };
              wantedBy = [ "transmission.service" ];
              wants = [ "transmission-rpc-forward.service" ];
            };
            transmission-rpc-forward =
              let
                inner = pkgs.writeShellScript "transmission-rpc-into-netns" ''
                  exec ${pkgs.iproute2}/bin/ip netns exec ${piaNamespace} \
                    ${pkgs.socat}/bin/socat - TCP:127.0.0.1:${toString servicePort}
                '';
              in
              {
                after = [ "transmission.service" ];
                bindsTo = [ "transmission.service" ];
                description = "Forward host 127.0.0.1:${toString servicePort} into the PIA netns";
                partOf = [ "transmission.service" ];
                serviceConfig = {
                  ExecStart = pkgs.writeShellScript "transmission-rpc-forward" ''
                    exec ${pkgs.socat}/bin/socat \
                      TCP-LISTEN:${toString servicePort},reuseaddr,fork \
                      EXEC:${inner}
                  '';
                  Restart = "on-failure";
                  RestartSec = "5s";
                  Type = "simple";
                };
                wantedBy = [ "multi-user.target" ];
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
        nodes = {
          ${homeWebProxy}.services.nginx = {
            upstreams = {
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
              transmission = {
                servers = {
                  "${homeServiceAddress}:${builtins.toString servicePort}" = { };
                };
              };
            };
            virtualHosts = {
              "${serviceDomain}" = {
                acmeRoot = null;
                extraConfig = nginxAccessRules;
                forceSSL = true;
                locations = {
                  "/" = {
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                    proxyPass = "http://transmission";
                  };
                  "/lidarr" = {
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                    proxyPass = "http://lidarr";
                  };
                  "/prowlarr" = {
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                    proxyPass = "http://prowlarr";
                  };
                  "/radarr" = {
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                    proxyPass = "http://radarr";
                  };
                  "/readarr" = {
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                    proxyPass = "http://readarr";
                  };
                  "/sonarr" = {
                    extraConfig = ''
                      client_max_body_size    0;
                    '';
                    proxyPass = "http://sonarr";
                  };
                };
                useACMEHost = globals.domains.main;
              };
            };
          };
        };
      };
    }

  ;
}
