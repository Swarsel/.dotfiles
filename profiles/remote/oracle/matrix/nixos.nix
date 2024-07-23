{ config, pkgs, sops, ... }:
let
  matrixDomain = "swatrix.swarsel.win";
in
{

  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    gnupg
    ssh-to-age
    matrix-synapse
    lottieconverter
    ffmpeg
  ];

  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/sops" ];
    defaultSopsFile = "/root/.dotfiles/secrets/omatrix/secrets.yaml";
    validateSopsFiles = false;
    secrets = {
      dnstokenfull = { owner = "acme"; };
      matrixsharedsecret = { owner = "matrix-synapse"; };
      mautrixtelegram_as = { owner = "matrix-synapse"; };
      mautrixtelegram_hs = { owner = "matrix-synapse"; };
      mautrixtelegram_api_id = { owner = "matrix-synapse"; };
      mautrixtelegram_api_hash = { owner = "matrix-synapse"; };
    };
    templates = {
      "certs.secret".content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder.dnstokenfull}
      '';
      "matrix_user_register.sh".content = ''
        register_new_matrix_user -k ${config.sops.placeholder.matrixsharedsecret} http://localhost:8008
      '';
      mautrixtelegram = {
        owner = "matrix-synapse";
        content = ''
          MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder.mautrixtelegram_as}
          MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder.mautrixtelegram_hs}
          MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder.mautrixtelegram_api_id}
          MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder.mautrixtelegram_api_hash}
        '';
      };
      matrixshared = {
        owner = "matrix-synapse";
        content = ''
          registration_shared_secret: ${config.sops.placeholder.matrixsharedsecret}
        '';
      };
    };
  };

  documentation = {
    enable = false;
  };

  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults.email = "mrswarsel@gmail.com";
    defaults.dnsProvider = "cloudflare";
    defaults.environmentFile = "${config.sops.templates."certs.secret".path}";
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    virtualHosts = {

      "swatrix.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations = {
          "~ ^(/_matrix|/_synapse/client)" = {
            proxyPass = "http://localhost:8008";
            extraConfig = ''
              client_max_body_size 0;
            '';
          };
        };
      };
    };
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = false;
  networking = {
    hostName = "swatrix";
    enableIPv6 = false;
    domain = "swarsel.win";
    firewall.extraCommands = ''
      iptables -I INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 8008 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 29317 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 29318 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 29328 -j ACCEPT
    '';
  };
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../../secrets/keys/authorized_keys
  ];

  system.stateVersion = "23.11"; # TEMPLATE - but probably no need to change

  environment.shellAliases = {
    nswitch = "cd ~/.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };

  boot.loader.grub.device = "nodev";

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
    settings.app_service_config_files = [
      "/var/lib/matrix-synapse/telegram-registration.yaml"
      "/var/lib/matrix-synapse/whatsapp-registration.yaml"
      "/var/lib/matrix-synapse/signal-registration.yaml"
      "/var/lib/matrix-synapse/doublepuppet.yaml"
    ];
    enable = true;
    settings = {
      server_name = matrixDomain;
      public_baseurl = "https://${matrixDomain}";
    };
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
    registerToSynapse = false; # this has the same effect as registering to app_service_config_file above
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

}
