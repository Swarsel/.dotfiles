{ config, lib, pkgs, modulesPath, sops, ... }:
let
  matrixDomain = "swatrix.swarsel.win";
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

  config = lib.mkIf config.swarselsystems.server.matrix {
    environment.systemPackages = with pkgs; [
      matrix-synapse
      lottieconverter
      ffmpeg
    ];

    sops = {
      secrets = {
        matrixsharedsecret = { owner = "matrix-synapse"; };
        mautrixtelegram_as = { owner = "matrix-synapse"; };
        mautrixtelegram_hs = { owner = "matrix-synapse"; };
        mautrixtelegram_api_id = { owner = "matrix-synapse"; };
        mautrixtelegram_api_hash = { owner = "matrix-synapse"; };
      };
      templates = {
        "matrix_user_register.sh".content = ''
          register_new_matrix_user -k ${config.sops.placeholder.matrixsharedsecret} http://localhost:8008
        '';
        matrixshared = {
          owner = "matrix-synapse";
          content = ''
            registration_shared_secret: ${config.sops.placeholder.matrixsharedsecret}
          '';
        };
        mautrixtelegram = {
          owner = "matrix-synapse";
          content = ''
            MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder.mautrixtelegram_as}
            MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder.mautrixtelegram_hs}
            MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder.mautrixtelegram_api_id}
            MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder.mautrixtelegram_api_hash}
          '';
        };
      };
    };

    services.postgresql = {
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

    services.matrix-synapse = {
      enable = true;
      settings = {
        app_service_config_files = [
          "/var/lib/matrix-synapse/telegram-registration.yaml"
          "/var/lib/matrix-synapse/whatsapp-registration.yaml"
          "/var/lib/matrix-synapse/signal-registration.yaml"
          "/var/lib/matrix-synapse/doublepuppet.yaml"
        ];
        server_name = matrixDomain;
        public_baseurl = "https://${matrixDomain}";
        listeners = [
          {
            port = 8008;
            bind_addresses = [ "0.0.0.0" ];
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

    services.mautrix-telegram = {
      enable = true;
      environmentFile = config.sops.templates.mautrixtelegram.path;
      settings = {
        homeserver = {
          address = "http://localhost:8008";
          domain = matrixDomain;
        };
        appservice = {
          address = "http://localhost:29317";
          hostname = "0.0.0.0";
          port = "29317";
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
    systemd.services.mautrix-telegram.path = with pkgs; [
      lottieconverter # for animated stickers conversion, unfree package
      ffmpeg # if converting animated stickers to webm (very slow!)
    ];

    services.mautrix-whatsapp = {
      enable = true;
      registerToSynapse = false;
      settings = {
        homeserver = {
          address = "http://localhost:8008";
          domain = matrixDomain;
        };
        appservice = {
          address = "http://localhost:29318";
          hostname = "0.0.0.0";
          port = 29318;
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
            "*" = "relaybot";
            "@swarsel:${matrixDomain}" = "admin";
          };
        };
      };
    };

    services.mautrix-signal = {
      enable = true;
      registerToSynapse = false;
      settings = {
        homeserver = {
          address = "http://localhost:8008";
          domain = matrixDomain;
        };
        appservice = {

          address = "http://localhost:29328";
          hostname = "0.0.0.0";
          port = 29328;
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
            "*" = "relaybot";
            "@swarsel:${matrixDomain}" = "admin";
          };
        };
      };
    };

    # restart the bridges daily. this is done for the signal bridge mainly which stops carrying
    # messages out after a while.

    systemd.timers."restart-bridges" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1d";
        OnUnitActiveSec = "1d";
        Unit = "restart-bridges.service";
      };
    };

    systemd.services."restart-bridges" = {
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

    services.nginx = {
      virtualHosts = {
        "swatrix.swarsel.win" = {
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
              addr = "0.0.0.0";
              port = 443;
              ssl = true;
            }
          ];
          locations = {
            "~ ^(/_matrix|/_synapse/client)" = {
              proxyPass = "http://localhost:8008";
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
