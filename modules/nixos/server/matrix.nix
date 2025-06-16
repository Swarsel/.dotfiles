{ lib, config, pkgs, ... }:
let
  matrixDomain = "swatrix.swarsel.win";
  serviceName = "matrix";
  synapsePort = 8008;
  synapseUser = "matrix-synapse";
  whatsappPort = 29318;
  telegramPort = 29317;
  signalPort = 29328;

  baseUrl = "https://${matrixDomain}";
  clientConfig."m.homeserver".base_url = baseUrl;
  serverConfig."m.server" = "${matrixDomain}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {
    environment.systemPackages = with pkgs; [
      matrix-synapse
      lottieconverter
      ffmpeg
    ];

    sops = {
      secrets = {
        matrixsharedsecret = { owner = synapseUser; };
        mautrixtelegram_as = { owner = synapseUser; };
        mautrixtelegram_hs = { owner = synapseUser; };
        mautrixtelegram_api_id = { owner = synapseUser; };
        mautrixtelegram_api_hash = { owner = synapseUser; };
      };
      templates = {
        "matrix_user_register.sh".content = ''
          register_new_matrix_user -k ${config.sops.placeholder.matrixsharedsecret} http://localhost:${builtins.toString synapsePort}
        '';
        matrixshared = {
          owner = synapseUser;
          content = ''
            registration_shared_secret: ${config.sops.placeholder.matrixsharedsecret}
          '';
        };
        mautrixtelegram = {
          owner = synapseUser;
          content = ''
            MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder.mautrixtelegram_as}
            MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder.mautrixtelegram_hs}
            MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder.mautrixtelegram_api_id}
            MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder.mautrixtelegram_api_hash}
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 8008 8448 ];

    systemd = {
      timers."restart-bridges" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1d";
          OnUnitActiveSec = "1d";
          Unit = "restart-bridges.service";
        };
      };

      services = {
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
        mautrix-telegram.path = with pkgs; [
          lottieconverter # for animated stickers conversion, unfree package
          ffmpeg # if converting animated stickers to webm (very slow!)
        ];
      };
    };

    services = {
      postgresql = {
        enable = true;
        initialScript = pkgs.writeText "synapse-init.sql" ''
          CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
          CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
          CREATE ROLE "mautrix-telegram" WITH LOGIN PASSWORD 'telegram';
          CREATE DATABASE "mautrix-telegram" WITH OWNER "mautrix-telegram"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
          CREATE ROLE "mautrix-whatsapp" WITH LOGIN PASSWORD 'whatsapp';
          CREATE DATABASE "mautrix-whatsapp" WITH OWNER "mautrix-whatsapp"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
          CREATE ROLE "mautrix-signal" WITH LOGIN PASSWORD 'signal';
          CREATE DATABASE "mautrix-signal" WITH OWNER "mautrix-signal"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
        '';
      };

      matrix-synapse = {
        enable = true;
        dataDir = "/Vault/data/matrix-synapse";
        settings = {
          app_service_config_files =
            let
              inherit (config.services.matrix-synapse) dataDir;
            in
            [
              "${dataDir}/telegram-registration.yaml"
              "${dataDir}/whatsapp-registration.yaml"
              "${dataDir}/signal-registration.yaml"
              "${dataDir}/doublepuppet.yaml"
            ];
          server_name = matrixDomain;
          public_baseurl = "https://${matrixDomain}";
          listeners = [
            {
              port = synapsePort;
              bind_addresses = [
                "0.0.0.0"
                # "::1"
              ];
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [ "client" "federation" ];
                  compress = true;
                }
              ];
            }
          ];
        };
        extraConfigFiles = [
          config.sops.templates.matrixshared.path
        ];
      };

      mautrix-telegram = {
        enable = true;
        environmentFile = config.sops.templates.mautrixtelegram.path;
        registerToSynapse = false;
        settings = {
          homeserver = {
            address = "http://localhost:${builtins.toString synapsePort}";
            domain = matrixDomain;
          };
          appservice = {
            address = "http://localhost:${builtins.toString telegramPort}";
            hostname = "0.0.0.0";
            port = telegramPort;
            provisioning.enabled = true;
            id = "telegram";
            # ephemeral_events = true; # not needed due to double puppeting
            public = {
              enabled = false;
            };
            database = "postgresql:///mautrix-telegram?host=/run/postgresql";
          };
          bridge = {
            relaybot.authless_portals = true;
            allow_avatar_remove = true;
            allow_contact_info = true;
            sync_channel_members = true;
            startup_sync = true;
            sync_create_limit = 0;
            sync_direct_chats = true;
            telegram_link_preview = true;
            permissions = {
              "*" = "relaybot";
              "@swarsel:${matrixDomain}" = "admin";
            };
            animated_sticker = {
              target = "gif";
              args = {
                width = 256;
                height = 256;
                fps = 30; # only for webm
                background = "020202"; # only for gif, transparency not supported
              };
            };
          };
        };
      };

      mautrix-whatsapp = {
        enable = true;
        registerToSynapse = false;
        settings = {
          homeserver = {
            address = "http://localhost:${builtins.toString synapsePort}";
            domain = matrixDomain;
          };
          appservice = {
            address = "http://localhost:${builtins.toString whatsappPort}";
            hostname = "0.0.0.0";
            port = whatsappPort;
            database = {
              type = "postgres";
              uri = "postgresql:///mautrix-whatsapp?host=/run/postgresql";
            };
          };
          bridge = {
            displayname_template = "{{or .FullName .PushName .JID}} (WA)";
            history_sync = {
              backfill = true;
              max_initial_conversations = -1;
              message_count = -1;
              request_full_sync = true;
              full_sync_config = {
                days_limit = 900;
                size_mb_limit = 5000;
                storage_quota_mb = 5000;
              };
            };
            login_shared_secret_map = {
              matrixDomain = "as_token:doublepuppet";
            };
            sync_manual_marked_unread = true;
            send_presence_on_typing = true;
            parallel_member_sync = true;
            url_previews = true;
            caption_in_message = true;
            extev_polls = true;
            permissions = {
              "*" = "relay";
              "@swarsel:${matrixDomain}" = "admin";
            };
          };
        };
      };

      mautrix-signal = {
        enable = true;
        registerToSynapse = false;
        settings = {
          homeserver = {
            address = "http://localhost:${builtins.toString synapsePort}";
            domain = matrixDomain;
          };
          appservice = {
            address = "http://localhost:${builtins.toString signalPort}";
            hostname = "0.0.0.0";
            port = signalPort;
            database = {
              type = "postgres";
              uri = "postgresql:///mautrix-signal?host=/run/postgresql";
            };
          };
          bridge = {
            displayname_template = "{{or .ContactName .ProfileName .PhoneNumber}} (Signal)";
            login_shared_secret_map = {
              matrixDomain = "as_token:doublepuppet";
            };
            caption_in_message = true;
            permissions = {
              "*" = "relay";
              "@swarsel:${matrixDomain}" = "admin";
            };
          };
        };
      };
    };

    # restart the bridges daily. this is done for the signal bridge mainly which stops carrying
    # messages out after a while.


    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "192.168.1.2:${builtins.toString synapsePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${matrixDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          listen = [
            {
              addr = "0.0.0.0";
              port = 8448;
              ssl = true;
              extraParameters = [
                "default_server"
              ];
            }
            {
              addr = "[::0]";
              port = 8448;
              ssl = true;
              extraParameters = [
                "default_server"
              ];
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
            "~ ^(/_matrix|/_synapse/client)" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
            "= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
            "= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
          };
        };
      };
    };
  };
}
