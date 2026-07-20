{
  flake.modules.nixos.matrix =
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
      inherit (config.swarselsystems) sopsFile;
      inherit
        (confLib.gen {
          name = "matrix";
          port = 8008;
          user = "matrix-synapse";
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceGroup
        serviceName
        servicePort
        serviceUser
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        idmServer
        isHome
        isProxied
        nginxAccessRules
        webProxy
        webProxyIf
        ;

      kanidmDomain = globals.services.kanidm.domain;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";

      federationPort = 8448;
      whatsappPort = 29318;
      telegramPort = 29317;
      signalPort = 29328;
      baseUrl = "https://${serviceDomain}";
      clientConfig."m.homeserver".base_url = baseUrl;
      serverConfig."m.server" = "${serviceDomain}:443";
      mkWellKnown = data: ''
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
        return 200 '${builtins.toJSON data}';
      '';
    in
    {
      imports = [
        self.modules.nixos.postgresql
      ];
      config = {
        swarselsystems.enabledServerModules = [ "matrix" ];
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "OK";
            path = "/health";
          };
          networks = lib.mkMerge [
            (confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; })
            {
              ${webProxyIf}.hosts = lib.mkIf isProxied {
                ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ federationPort ];
              };
            }
          ];
        };
        sops = {
          secrets = {
            kanidm-matrix = {
              group = serviceGroup;
              mode = "0440";
              owner = serviceUser;
              sopsFile = kanidmSopsFile;
            };
            matrix-doublepuppet-token = {
              inherit sopsFile;
            };
            matrix-shared-secret = {
              inherit sopsFile;
              owner = serviceUser;
            };
            mautrix-signal-pickle-key = {
              inherit sopsFile;
            };
            mautrix-telegram-api-hash = {
              inherit sopsFile;
              owner = serviceUser;
            };
            mautrix-telegram-api-id = {
              inherit sopsFile;
              owner = serviceUser;
            };
            mautrix-telegram-as-token = {
              inherit sopsFile;
              owner = serviceUser;
            };
            mautrix-telegram-hs-token = {
              inherit sopsFile;
              owner = serviceUser;
            };
            mautrix-whatsapp-pickle-key = {
              inherit sopsFile;
            };
          };
          templates = {
            "doublepuppet.yaml" = {
              content = ''
                id: doublepuppet
                url:
                as_token: ${config.sops.placeholder.matrix-doublepuppet-token}
                hs_token: notused
                sender_localpart: notused
                rate_limited: false
                namespaces:
                  users:
                  - regex: '@.*:${builtins.replaceStrings [ "." ] [ "\\." ] serviceDomain}'
                    exclusive: false
              '';
              owner = serviceUser;
            };
            "matrix_user_register.sh".content = ''
              register_new_matrix_user -k ${config.sops.placeholder.matrix-shared-secret} http://localhost:${builtins.toString servicePort}
            '';
            matrixshared = {
              content = ''
                registration_shared_secret: ${config.sops.placeholder.matrix-shared-secret}
              '';
              owner = serviceUser;
            };
            mautrixsignal = {
              content = ''
                MAUTRIX_SIGNAL_PICKLE_KEY=${config.sops.placeholder.mautrix-signal-pickle-key}
                MAUTRIX_SIGNAL_BRIDGE_LOGIN_SHARED_SECRET=as_token:${config.sops.placeholder.matrix-doublepuppet-token}
              '';
              owner = serviceUser;
            };
            mautrixtelegram = {
              content = ''
                MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder.mautrix-telegram-as-token}
                MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder.mautrix-telegram-hs-token}
                MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder.mautrix-telegram-api-id}
                MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder.mautrix-telegram-api-hash}
                MAUTRIX_TELEGRAM_DOUBLEPUPPET=${config.sops.placeholder.matrix-doublepuppet-token}
              '';
              owner = serviceUser;
            };
            mautrixwhatsapp = {
              content = ''
                MAUTRIX_WHATSAPP_PICKLE_KEY=${config.sops.placeholder.mautrix-whatsapp-pickle-key}
                MAUTRIX_WHATSAPP_BRIDGE_LOGIN_SHARED_SECRET=as_token:${config.sops.placeholder.matrix-doublepuppet-token}
              '';
              owner = serviceUser;
            };
          };
        };
        # restart the bridges daily. this is done for the signal bridge mainly which stops carrying
        # messages out after a while.
        users.persistentIds = {
          mautrix-signal = confLib.mkIds 993;
          mautrix-telegram = confLib.mkIds 991;
          mautrix-whatsapp = confLib.mkIds 992;
        };
        services = {
          matrix-synapse = {
            enable = true;
            dataDir = "/var/lib/matrix-synapse";
            extraConfigFiles = [
              config.sops.templates.matrixshared.path
            ];
            settings = {
              app_service_config_files =
                let
                  inherit (config.services.matrix-synapse) dataDir;
                in
                [
                  "${dataDir}/telegram-registration.yaml"
                  "${dataDir}/whatsapp-registration.yaml"
                  "${dataDir}/signal-registration.yaml"
                  config.sops.templates."doublepuppet.yaml".path
                ];
              listeners = [
                {
                  bind_addresses = [
                    "0.0.0.0"
                    # "::1"
                  ];
                  port = servicePort;
                  resources = [
                    {
                      compress = true;
                      names = [
                        "client"
                        "federation"
                      ];
                    }
                  ];
                  tls = false;
                  type = "http";
                  x_forwarded = true;
                }
              ];
              oidc_providers = [
                {
                  client_id = serviceName;
                  client_secret_path = config.sops.secrets.kanidm-matrix.path;
                  idp_id = "kanidm";
                  idp_name = "Kanidm SSO";
                  issuer = "https://${kanidmDomain}/oauth2/openid/${serviceName}";
                  scopes = [
                    "openid"
                    "email"
                    "profile"
                  ];
                  user_mapping_provider.config = {
                    display_name_template = "{{ user.name }}";
                    email_template = "{{ user.email }}";
                    localpart_template = "{{ user.preferred_username }}";
                    subject_claim = "sub";
                  };
                  user_profile_method = "userinfo_endpoint";
                }
              ];
              public_baseurl = "https://${serviceDomain}";
              server_name = serviceDomain;
            };
          };
          mautrix-signal = {
            enable = true;
            environmentFile = config.sops.templates.mautrixsignal.path;
            registerToSynapse = false;
            settings = {
              appservice = {
                address = "http://localhost:${builtins.toString signalPort}";
                hostname = "0.0.0.0";
                port = signalPort;
              };
              bridge.permissions = {
                "*" = "relay";
                "@swarsel:${serviceDomain}" = "admin";
              };
              database = {
                type = "postgres";
                uri = "postgresql:///mautrix-signal?host=/run/postgresql";
              };
              encryption = {
                allow = true;
                default = true;
                pickle_key = "$MAUTRIX_SIGNAL_PICKLE_KEY";
              };
              homeserver = {
                address = "http://localhost:${builtins.toString servicePort}";
                domain = serviceDomain;
              };
              network.displayname_template = "{{or .ContactName .ProfileName .PhoneNumber}} (Signal)";
            };
          };
          mautrix-telegram = {
            enable = true;
            environmentFile = config.sops.templates.mautrixtelegram.path;
            registerToSynapse = false;
            settings = {
              appservice = {
                address = "http://localhost:${builtins.toString telegramPort}";
                database = "postgresql:///mautrix-telegram?host=/run/postgresql";
                hostname = "0.0.0.0";
                id = "telegram";
                port = telegramPort;
                provisioning.enabled = true;
                # ephemeral_events = true; # not needed due to double puppeting
                public.enabled = false;
              };
              bridge = {
                allow_avatar_remove = true;
                allow_contact_info = true;
                animated_sticker = {
                  args = {
                    background = "020202"; # only for gif, transparency not supported
                    fps = 30; # only for webm
                    height = 256;
                    width = 256;
                  };
                  target = "gif";
                };
                encryption = {
                  allow = true;
                  default = false;
                };
                login_shared_secret_map = {
                  ${serviceDomain} = "as_token:$MAUTRIX_TELEGRAM_DOUBLEPUPPET";
                };
                permissions = {
                  "*" = "relaybot";
                  "@swarsel:${serviceDomain}" = "admin";
                };
                relaybot.authless_portals = true;
                startup_sync = true;
                sync_channel_members = true;
                sync_create_limit = 0;
                sync_direct_chats = true;
                telegram_link_preview = true;
              };
              homeserver = {
                address = "http://localhost:${builtins.toString servicePort}";
                domain = serviceDomain;
              };
            };
          };
          mautrix-whatsapp = {
            enable = true;
            environmentFile = config.sops.templates.mautrixwhatsapp.path;
            registerToSynapse = false;
            settings = {
              appservice = {
                address = "http://localhost:${builtins.toString whatsappPort}";
                hostname = "0.0.0.0";
                port = whatsappPort;
              };
              backfill.enabled = true;
              bridge.permissions = {
                "*" = "relay";
                "@swarsel:${serviceDomain}" = "admin";
              };
              database = {
                type = "postgres";
                uri = "postgresql:///mautrix-whatsapp?host=/run/postgresql";
              };
              encryption = {
                allow = true;
                default = true;
                pickle_key = "$MAUTRIX_WHATSAPP_PICKLE_KEY";
              };
              homeserver = {
                address = "http://localhost:${builtins.toString servicePort}";
                domain = serviceDomain;
              };
              network = {
                displayname_template = "{{or .FullName .PushName .Phone}} (WA)";
                extev_polls = true;
                history_sync = {
                  full_sync_config = {
                    days_limit = 900;
                    size_mb_limit = 5000;
                    storage_quota_mb = 5000;
                  };
                  max_initial_conversations = -1;
                  request_full_sync = true;
                };
                send_presence_on_typing = true;
                url_previews = true;
              };
            };
          };
          postgresql = {
            ensureDatabases = [
              "matrix-synapse"
              "mautrix-telegram"
              "mautrix-whatsapp"
              "mautrix-signal"
            ];
            ensureUsers = [
              {
                ensureDBOwnership = true;
                name = "matrix-synapse";
              }
              {
                ensureDBOwnership = true;
                name = "mautrix-telegram";
              }
              {
                ensureDBOwnership = true;
                name = "mautrix-whatsapp";
              }
              {
                ensureDBOwnership = true;
                name = "mautrix-signal";
              }
            ];
            initialScript = pkgs.writeText "synapse-init.sql" ''
              CREATE DATABASE "matrix-synapse"
                TEMPLATE template0
                LC_COLLATE = "C"
                LC_CTYPE = "C";
            '';
          };
        };
        environment = {
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/matrix-synapse";
                group = serviceGroup;
                user = serviceUser;
              }
              {
                directory = "/var/lib/mautrix-whatsapp";
                group = "mautrix-whatsapp";
                user = "mautrix-whatsapp";
              }
              {
                directory = "/var/lib/mautrix-telegram";
                group = "mautrix-telegram";
                user = "mautrix-telegram";
              }
              {
                directory = "/var/lib/mautrix-signal";
                group = "mautrix-signal";
                user = "mautrix-signal";
              }
            ];
          };
          systemPackages = with pkgs; [
            matrix-synapse
            lottieconverter
            ffmpeg
          ];
        };
        # networking.firewall.allowedTCPPorts = [ servicePort federationPort ];
        systemd = {
          services = {
            mautrix-telegram.path = with pkgs; [
              lottieconverter # for animated stickers conversion, unfree package
              ffmpeg # if converting animated stickers to webm (very slow!)
            ];
            "restart-bridges" = {
              script = ''
                systemctl restart mautrix-whatsapp.service
                systemctl restart mautrix-signal.service
                systemctl restart mautrix-telegram.service
              '';
              serviceConfig = {
                Type = "oneshot";
                User = "root";
              };
            };
          };
          timers."restart-bridges" = {
            timerConfig = {
              OnBootSec = "1d";
              OnUnitActiveSec = "1d";
              Unit = "restart-bridges.service";
            };
            wantedBy = [ "timers.target" ];
          };
        };
        nodes =
          let
            genNginx = toAddress: extraConfig: {
              upstreams = {
                ${serviceName}.servers = {
                  "${toAddress}:${builtins.toString servicePort}" = { };
                };
              };
              virtualHosts = {
                "${serviceDomain}" = {
                  inherit extraConfig;
                  acmeRoot = null;
                  forceSSL = true;
                  listen = [
                    {
                      addr = "0.0.0.0";
                      extraParameters = [
                        "default_server"
                      ];
                      port = 8448;
                      ssl = true;
                    }
                    {
                      addr = "[::0]";
                      extraParameters = [
                        "default_server"
                      ];
                      port = 8448;
                      ssl = true;
                    }
                    {
                      addr = "0.0.0.0";
                      port = 443;
                      ssl = true;
                    }
                    {
                      addr = "[::0]";
                      port = 443;
                      ssl = true;
                    }
                  ];
                  locations = {
                    "= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
                    "= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
                    "~ ^(/_matrix|/_synapse/client)" = {
                      extraConfig = ''
                        client_max_body_size 0;
                      '';
                      proxyPass = "http://${serviceName}";
                    };
                  };
                  useACMEHost = globals.domains.main;
                };
              };
            };
          in
          lib.mkMerge [
            {
              ${idmServer} = confLib.mkKanidmOidcSystem {
                inherit kanidmSopsFile serviceDomain serviceName;
                originUrl = "https://${serviceDomain}/_synapse/client/oidc/callback";
              };
            }
            { ${webProxy}.services.nginx = genNginx serviceAddress ""; }
            { ${homeWebProxy}.services.nginx = genNginx homeServiceAddress nginxAccessRules; }
          ];

      };
    }

  ;
}
