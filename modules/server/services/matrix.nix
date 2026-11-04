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
        notificationMail
        webProxy
        webProxyIf
        ;

      kanidmDomain = globals.services.kanidm.domain;

      federationPort = 8448;
      whatsappPort = 29318;
      telegramPort = 29317;
      signalPort = 29328;
      ircPort = 8009;
      ircMediaPort = 11111;
      postgresRoles = [
        "matrix-synapse"
        "matrix-appservice-irc"
        "mautrix-discord"
        "mautrix-meta-instagram"
        "mautrix-telegram"
        "mautrix-whatsapp"
        "mautrix-signal"
      ];
      mkPostgresUri = role: password: "postgresql://${role}:${password}@/${role}?host=/run/postgresql";
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
        swarselsystems = {
          enabledServerModules = [ "matrix" ];
          server.postgresql.rolePasswordFiles = lib.genAttrs postgresRoles (
            role: config.sops.secrets."${role}-db-password".path
          );
        };
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
            (confLib.mkDualFirewallRules {
              tcpPorts = [
                servicePort
                ircMediaPort
              ];
            })
            {
              ${webProxyIf}.hosts = lib.mkIf isProxied {
                ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ federationPort ];
              };
            }
          ];
        };
        sops = {
          secrets =
            lib.mapAttrs' (id: _: lib.nameValuePair "matrix-irc-${id}-key" { }) (
              lib.filterAttrs (_: server: server ? onConnectCommands) config.repo.secrets.local.irc.servers
            )
            // {
              kanidm-matrix = {
                group = serviceGroup;
                mode = "0440";
                owner = serviceUser;
                rekey.keyPrefix = confLib.kanidmSecrets;
              };
              matrix-doublepuppet-token.rekey.generator.script = "hex";
              matrix-shared-secret = {
                owner = serviceUser;
                rekey.generator.script = "alnum";
              };
              mautrix-meta-instagram-as-token.rekey.generator.script = "hex";
              mautrix-meta-instagram-hs-token.rekey.generator.script = "hex";
              mautrix-meta-instagram-pickle-key.rekey.generator.script = "alnum";
              mautrix-signal-pickle-key.rekey.generator.script = "alnum";
              mautrix-telegram-api-hash.owner = serviceUser;
              mautrix-telegram-api-id.owner = serviceUser;
              mautrix-telegram-as-token = {
                owner = serviceUser;
                rekey.generator.script = "hex";
              };
              mautrix-telegram-hs-token = {
                owner = serviceUser;
                rekey.generator.script = "hex";
              };
              mautrix-whatsapp-pickle-key.rekey.generator.script = "alnum";
              notification-mail-pw.rekey.keyPrefix = notificationMail.keyPrefix;
            }
            // lib.genAttrs (map (role: "${role}-db-password") postgresRoles) (_: {
              owner = config.systemd.services.postgresql.serviceConfig.User;
              rekey.generator.script = "alnum";
            });
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
            "matrix-appservice-irc.yml" = {
              content = builtins.toJSON config.services.matrix-appservice-irc.settings;
              owner = "matrix-appservice-irc";
              restartUnits = [ "matrix-appservice-irc.service" ];
            };
            "matrix-database.yaml" = {
              content = builtins.toJSON {
                database = lib.recursiveUpdate config.services.matrix-synapse.settings.database {
                  args.password = config.sops.placeholder."matrix-synapse-db-password";
                };
              };
              owner = serviceUser;
            };
            "matrix-email.yaml" = {
              content = builtins.toJSON {
                email = {
                  app_name = "Matrix";
                  enable_notifs = true;
                  notif_from = "%(app)s <${notificationMail.address}>";
                  require_transport_security = true;
                  smtp_host = notificationMail.host;
                  smtp_pass = config.sops.placeholder.notification-mail-pw;
                  smtp_port = 587;
                  smtp_user = notificationMail.address;
                };
              };
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
            mautrixdiscord = {
              content = ''
                MAUTRIX_DISCORD_DB_PASSWORD=${config.sops.placeholder."mautrix-discord-db-password"}
                MAUTRIX_DISCORD_DOUBLEPUPPET=as_token:${config.sops.placeholder.matrix-doublepuppet-token}
              '';
              owner = serviceUser;
            };
            mautrixmetainstagram = {
              content = ''
                MAUTRIX_META_INSTAGRAM_DB_PASSWORD=${config.sops.placeholder."mautrix-meta-instagram-db-password"}
                MAUTRIX_META_INSTAGRAM_AS_TOKEN=${config.sops.placeholder.mautrix-meta-instagram-as-token}
                MAUTRIX_META_INSTAGRAM_HS_TOKEN=${config.sops.placeholder.mautrix-meta-instagram-hs-token}
                MAUTRIX_META_INSTAGRAM_PICKLE_KEY=${config.sops.placeholder.mautrix-meta-instagram-pickle-key}
                MAUTRIX_META_INSTAGRAM_DOUBLEPUPPET=as_token:${config.sops.placeholder.matrix-doublepuppet-token}
              '';
              owner = serviceUser;
            };
            mautrixsignal = {
              content = ''
                MAUTRIX_SIGNAL_DB_PASSWORD=${config.sops.placeholder."mautrix-signal-db-password"}
                MAUTRIX_SIGNAL_PICKLE_KEY=${config.sops.placeholder.mautrix-signal-pickle-key}
                MAUTRIX_SIGNAL_BRIDGE_LOGIN_SHARED_SECRET=as_token:${config.sops.placeholder.matrix-doublepuppet-token}
              '';
              owner = serviceUser;
            };
            mautrixtelegram = {
              content = ''
                MAUTRIX_TELEGRAM_DB_PASSWORD=${config.sops.placeholder."mautrix-telegram-db-password"}
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
                MAUTRIX_WHATSAPP_DB_PASSWORD=${config.sops.placeholder."mautrix-whatsapp-db-password"}
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
          matrix-appservice-irc = confLib.mkIds 943;
          mautrix-discord = confLib.mkIds 939;
          mautrix-meta.gid = 941;
          mautrix-meta-instagram = confLib.mkIds 942;
          mautrix-meta-registration.gid = 940;
          mautrix-signal = confLib.mkIds 993;
          mautrix-telegram = confLib.mkIds 991;
          mautrix-whatsapp = confLib.mkIds 992;
        };
        services = {
          matrix-appservice-irc = {
            enable = true;
            port = ircPort;
            registrationUrl = "http://localhost:${builtins.toString ircPort}";
            settings = {
              database = {
                connectionString =
                  mkPostgresUri "matrix-appservice-irc"
                    config.sops.placeholder."matrix-appservice-irc-db-password";
                engine = "postgres";
              };
              homeserver = {
                domain = serviceDomain;
                url = "http://localhost:${builtins.toString servicePort}";
              };
              ircService = {
                logging = {
                  level = "info";
                  toConsole = true;
                };
                mediaProxy = {
                  bindPort = ircMediaPort;
                  publicUrl = "https://${serviceDomain}/media";
                };
                permissions."@swarsel:${serviceDomain}" = "admin";
                servers = lib.mapAttrs' (
                  id: server:
                  lib.nameValuePair server.address (
                    lib.recursiveUpdate {
                      botConfig = {
                        enabled = false;
                        joinChannelsIfNoUsers = false;
                        nick = "MatrixBridge";
                        username = "matrixbridge";
                      };
                      dynamicChannels = {
                        aliasTemplate = "#${id}_$CHANNEL";
                        createAlias = true;
                        enabled = true;
                        federate = false;
                        joinRule = "public";
                        published = false;
                        useHomeserverDirectory = false;
                      };
                      ircClients = {
                        allowNickChanges = true;
                        idleTimeout = 0;
                        kickOn = {
                          channelJoinFailure = true;
                          ircConnectionFailure = true;
                          userQuit = true;
                        };
                        lineLimit = 3;
                        maxClients = 30;
                        nickTemplate = "$DISPLAY[m]";
                        realnameFormat = "mxid";
                      };
                      matrixClients = {
                        displayName = "$NICK (IRC)";
                        joinAttempts = -1;
                        userTemplate = "@${id}_$NICK";
                      };
                      membershipLists = {
                        enabled = true;
                        floodDelayMs = 10000;
                        global = {
                          ircToMatrix = {
                            incremental = true;
                            initial = false;
                            requireMatrixJoined = false;
                          };
                          matrixToIrc = {
                            incremental = true;
                            initial = true;
                          };
                        };
                        ignoreIdleUsersOnStartup = {
                          enabled = true;
                          idleForHours = 720;
                        };
                      };
                      networkId = id;
                      privateMessages = {
                        enabled = true;
                        federate = false;
                      };
                      sasl = true;
                      sendConnectionMessages = true;
                      ssl = true;
                    } (builtins.removeAttrs server [ "address" ])
                  )
                ) config.repo.secrets.local.irc.servers;
              };
            };
          };
          matrix-synapse = {
            enable = true;
            dataDir = "/var/lib/matrix-synapse";
            extraConfigFiles = [
              config.sops.templates."matrix-database.yaml".path
              config.sops.templates."matrix-email.yaml".path
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
                  "/var/lib/matrix-appservice-irc/registration.yml"
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
          mautrix-discord = {
            enable = true;
            environmentFile = config.sops.templates.mautrixdiscord.path;
            settings = {
              appservice.database = {
                type = "postgres";
                uri = mkPostgresUri "mautrix-discord" "$MAUTRIX_DISCORD_DB_PASSWORD";
              };
              bridge = {
                backfill.forward_limits = {
                  initial = {
                    channel = 50;
                    dm = 50;
                    thread = 50;
                  };
                  missed = {
                    channel = 50;
                    dm = 50;
                    thread = 50;
                  };
                };
                encryption = {
                  allow = true;
                  default = true;
                };
                login_shared_secret_map.${serviceDomain} = "as_token:$MAUTRIX_DISCORD_DOUBLEPUPPET";
                permissions = {
                  "*" = "relay";
                  "@swarsel:${serviceDomain}" = "admin";
                };
              };
              homeserver = {
                address = "http://localhost:${builtins.toString servicePort}";
                domain = serviceDomain;
              };
            };
          };
          mautrix-meta.instances.instagram = {
            enable = true;
            environmentFile = config.sops.templates.mautrixmetainstagram.path;
            settings = {
              appservice = {
                as_token = "$MAUTRIX_META_INSTAGRAM_AS_TOKEN";
                hs_token = "$MAUTRIX_META_INSTAGRAM_HS_TOKEN";
              };
              backfill.enabled = true;
              bridge.permissions = {
                "*" = "relay";
                "@swarsel:${serviceDomain}" = "admin";
              };
              database = {
                type = "postgres";
                uri = mkPostgresUri "mautrix-meta-instagram" "$MAUTRIX_META_INSTAGRAM_DB_PASSWORD";
              };
              double_puppet.secrets.${serviceDomain} = "$MAUTRIX_META_INSTAGRAM_DOUBLEPUPPET";
              encryption.pickle_key = "$MAUTRIX_META_INSTAGRAM_PICKLE_KEY";
              homeserver = {
                address = "http://localhost:${builtins.toString servicePort}";
                domain = serviceDomain;
              };
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
                uri = mkPostgresUri "mautrix-signal" "$MAUTRIX_SIGNAL_DB_PASSWORD";
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
                database = mkPostgresUri "mautrix-telegram" "$MAUTRIX_TELEGRAM_DB_PASSWORD";
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
                uri = mkPostgresUri "mautrix-whatsapp" "$MAUTRIX_WHATSAPP_DB_PASSWORD";
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
            ensureDatabases = postgresRoles;
            ensureUsers = map (name: {
              inherit name;
              ensureDBOwnership = true;
            }) postgresRoles;
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
                directory = "/var/lib/matrix-appservice-irc";
                group = "matrix-appservice-irc";
                user = "matrix-appservice-irc";
              }
              {
                directory = "/var/lib/mautrix-discord";
                group = "mautrix-discord";
                user = "mautrix-discord";
              }
              {
                directory = "/var/lib/mautrix-meta-instagram";
                group = "mautrix-meta";
                user = "mautrix-meta-instagram";
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
            matrix-appservice-irc.serviceConfig.ExecStart = lib.mkForce (
              lib.concatStringsSep " " [
                (lib.getExe pkgs.matrix-appservice-irc)
                "--config ${config.sops.templates."matrix-appservice-irc.yml".path}"
                "--file /var/lib/matrix-appservice-irc/registration.yml"
                "--port ${builtins.toString ircPort}"
              ]
            );
            mautrix-telegram.path = with pkgs; [
              lottieconverter # for animated stickers conversion, unfree package
              ffmpeg # if converting animated stickers to webm (very slow!)
            ];
            restart-bridges = {
              script = ''
                systemctl restart mautrix-whatsapp.service
                systemctl restart mautrix-signal.service
                systemctl restart mautrix-telegram.service
                systemctl restart mautrix-meta-instagram.service
                systemctl restart mautrix-discord.service
              '';
              serviceConfig = {
                Type = "oneshot";
                User = "root";
              };
            };
          };
          timers.restart-bridges = {
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
                "${serviceName}-irc-media".servers = {
                  "${toAddress}:${builtins.toString ircMediaPort}" = { };
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
                    "/media/".proxyPass = "http://${serviceName}-irc-media/";
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
                inherit serviceDomain serviceName;
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
