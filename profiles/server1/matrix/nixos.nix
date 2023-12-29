{ config, pkgs, modulesPath, ... }:

     {
       imports = [
         (modulesPath + "/virtualisation/proxmox-lxc.nix")
         ./hardware-configuration.nix
       ];

       environment.systemPackages = with pkgs; [
         git
         gnupg
         ssh-to-age
       ];

       services.xserver = {
         layout = "us";
         xkbVariant = "altgr-intl";
       };

       nix.settings.experimental-features = ["nix-command" "flakes"];

       sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
       sops.defaultSopsFile = "/.dotfiles/secrets/matrix/secrets.yaml";
       sops.validateSopsFiles = false;

       sops.secrets.matrixsharedsecret = {owner="matrix-synapse";};
       sops.templates.matrixshared.owner = "matrix-synapse";
       sops.templates.matrixshared.content = ''
       registration_shared_secret: ${config.sops.placeholder.matrixsharedsecret}
       '';
       sops.secrets.mautrixtelegram_as = {owner="matrix-synapse";};
       sops.secrets.mautrixtelegram_hs = {owner="matrix-synapse";};
       sops.secrets.mautrixtelegram_api_id = {owner="matrix-synapse";};
       sops.secrets.mautrixtelegram_api_hash = {owner="matrix-synapse";};
       sops.templates.mautrixtelegram.owner = "matrix-synapse";
       sops.templates.mautrixtelegram.content = ''
       MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder.mautrixtelegram_as}
       MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder.mautrixtelegram_hs}
      MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder.mautrixtelegram_api_id}
      MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder.mautrixtelegram_api_hash}
      '';

       proxmoxLXC.manageNetwork = true; # manage network myself
       proxmoxLXC.manageHostName = false; # manage hostname myself
       networking.hostName = "matrix"; # Define your hostname.
       networking.useDHCP = true;
       networking.enableIPv6 = false;
       networking.firewall.enable = false;
       services.openssh = {
         enable = true;
         settings.PermitRootLogin = "yes";
         listenAddresses = [{
                            port = 22;
                            addr = "0.0.0.0";
                          }];
       };
       users.users.root.openssh.authorizedKeys.keyFiles = [
         ../../../secrets/keys/authorized_keys
       ];

       system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change
       # users.users.root.password = "TEMPLATE";

       environment.shellAliases = {
         nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
       };

       services.postgresql.enable = true;
       services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
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
     '';

        services.matrix-synapse = {
  settings.app_service_config_files = [
       # The registration file is automatically generated after starting the
       # appservice for the first time.
       # cp /var/lib/mautrix-telegram/telegram-registration.yaml \
       #   /var/lib/matrix-synapse/
       # chown matrix-synapse:matrix-synapse \
       #   /var/lib/matrix-synapse/telegram-registration.yaml
       "/var/lib/matrix-synapse/telegram-registration.yaml"
     ];
          enable = true;
          settings.server_name = "matrix2.swarsel.win";
          settings.public_baseurl = "https://matrix2.swarsel.win";
          extraConfigFiles = [
            config.sops.templates.matrixshared.path
          ];
          settings.listeners = [
            { port = 8008;
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

        services.mautrix-telegram = {
    enable = true;

    # file containing the appservice and telegram tokens
    environmentFile = config.sops.templates.mautrixtelegram.path;

    # The appservice is pre-configured to use SQLite by default.
    # It's also possible to use PostgreSQL.
    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = "matrix2.swarsel.win";
      };
      appservice = {
        address= "http://localhost:29317";
        tls_cert = false;
        tls_key = false;
        hostname = "0.0.0.0";
        port = "29317";
        provisioning.enabled = true;
        id = "telegram";
        public = {
          enabled = false;
        };

        # The service uses SQLite by default, but it's also possible to use
        # PostgreSQL instead:
        database = "postgresql:///mautrix-telegram?host=/run/postgresql";
      };
      bridge = {
        relaybot.authless_portals = true;
        permissions = {
          "*" = "relaybot";
          "@swarsel:matrix2.swarsel.win" = "admin";
        };

        # Animated stickers conversion requires additional packages in the
        # service's path.
        # If this isn't a fresh installation, clearing the bridge's uploaded
        # file cache might be necessary (make a database backup first!):
        # delete from telegram_file where \
        #   mime_type in ('application/gzip', 'application/octet-stream')
        animated_sticker = {
          target = "gif";
          args = {
            width = 256;
            height = 256;
            fps = 30;               # only for webm
            background = "020202";  # only for gif, transparency not supported
          };
        };
      };
    };
  };

  systemd.services.mautrix-telegram.path = with pkgs; [
    lottieconverter  # for animated stickers conversion, unfree package
    ffmpeg           # if converting animated stickers to webm (very slow!)
];
     }
