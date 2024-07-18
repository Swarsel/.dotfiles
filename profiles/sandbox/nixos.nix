{
  config,
  pkgs,
  sops,
  ...
}: let
  matrixDomain = "swatrix.swarsel.win";
in {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
    supportedFilesystems = ["zfs"];
    zfs.forceImportRoot = false;
    kernelModules = ["tun"];
    kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 2;
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.enp7s0.rp_filter" = 2;
    };
  };

  networking = {
    hostId = "8a8ad84a";
    hostName = "sandbox"; # Define your hostname.
    enableIPv6 = true;
    firewall.enable = false;
    firewall.extraCommands = ''
      sudo iptables -A OUTPUT ! -o lo -m owner --uid-owner vpn -j DROP
    '';
    iproute2 = {
      enable = true;
      rttablesExtraConfig = ''
        200     vpn
      '';
    };
  };

  hardware.graphics = {
    enable = true;
    hardware.enableAllFirmware = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  sound = {
    enable = true;
  };

  users = {
    groups = {
      vpn = {};
      mpd = {};
      navidrome = {
        gid = 61593;
      };
      spotifyd = {
        gid = 65136;
      };
    };
    users = {
      jellyfin = {
        extraGroups = ["video" "render"];
      };
      vpn = {
        isNormalUser = true;
        group = "vpn";
        home = "/home/vpn";
      };
      navidrome = {
        isSystemUser = true;
        uid = 61593;
        group = "navidrome";
        extraGroups = ["audio" "utmp"];
      };
      spotifyd = {
        isSystemUser = true;
        uid = 65136;
        group = "spotifyd";
        extraGroups = ["audio" "utmp"];
      };
      mpd = {
        isSystemUser = true;
        group = "mpd";
        extraGroups = ["audio" "utmp"];
      };
      swarsel = {
        isNormalUser = true;
        description = "Leon S";
        extraGroups = ["networkmanager" "wheel" "lp"];
        packages = with pkgs; [];
      };
      root = {
        openssh.authorizedKeys.keyFiles = [
          ../../secrets/keys/authorized_keys
        ];
      };
    };
  };

  fileSystems."/mnt/Eternor" = {
    device = "//192.168.1.3/Eternor";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=/etc/nixos/smb-secrets,uid=1000,gid=100"];
  };

  environment = {
    systemPackages = with pkgs; [
      git
      gnupg
      ssh-to-age
      lego
      nginx
      calibre
      openvpn
      jq
      iptables
      busybox
      wireguard-tools
      matrix-synapse
      lottieconverter
      ffmpeg
      pciutils
      alsa-utils
      mpv
      zfs
    ];
    etc = {
      "openvpn/iptables.sh" = {
        source = ../../scripts/server1/iptables.sh;
        mode = "0755";
      };
      "openvpn/update-resolv-conf" = {
        source = ../../scripts/server1/update-resolv-conf;
        mode = "0755";
      };
      "openvpn/routing.sh" = {
        source = ../../scripts/server1/routing.sh;
        mode = "0755";
      };
      "openvpn/ca.rsa.2048.crt" = {
        source = ../../secrets/certs/ca.rsa.2048.crt;
        mode = "0644";
      };
      "openvpn/crl.rsa.2048.pem" = {
        source = ../../secrets/certs/crl.rsa.2048.pem;
        mode = "0644";
      };
    };
    shellAliases = {
      nswitch = "cd ~/.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
    };
  };

  systemd = {
    timers."restart-bridges" = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1d";
        OnUnitActiveSec = "1d";
        Unit = "restart-bridges.service";
      };
    };

    services."restart-bridges" = {
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
  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change

  documentation = {
    enable = false;
  };

  sops = {
    age.sshKeyPaths = ["/etc/ssh/sops"];
    defaultSopsFile = "/root/.dotfiles/secrets/sandbox/secrets.yaml";
    validateSopsFiles = false;
    secrets = {
      dnstokenfull = {owner = "acme";};
      kavita = {owner = "kavita";};
      vpnuser = {};
      rpcuser = {owner = "vpn";};
      vpnpass = {};
      rpcpass = {owner = "vpn";};
      vpnprot = {};
      vpnloc = {};
      mpdpass = {owner = "mpd";};
    };
    templates = {
      "transmission-rpc" = {
        owner = "vpn";
        content = builtins.toJSON {
          rpc-username = config.sops.placeholder.rpcuser;
          rpc-password = config.sops.placeholder.rpcpass;
        };
      };

      pia.content = ''
        ${config.sops.placeholder.vpnuser}
        ${config.sops.placeholder.vpnpass}
      '';

      vpn.content = ''
        client
        dev tun
        proto ${config.sops.placeholder.vpnprot}
        remote ${config.sops.placeholder.vpnloc}
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        cipher aes-128-cbc
        auth sha1
        tls-client
        remote-cert-tls server

        auth-user-pass ${config.sops.templates.pia.path}
        compress
        verb 1
        reneg-sec 0

        crl-verify /etc/openvpn/crl.rsa.2048.pem
        ca /etc/openvpn/ca.rsa.2048.crt

        disable-occ
      '';
      "certs.secret".content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder.dnstokenfull}
      '';
    };
  };

  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults.email = "mrswarsel@gmail.com";
    defaults.dnsProvider = "cloudflare";
    defaults.environmentFile = "${config.sops.templates."certs.secret".path}";
  };

  services = {
    xserver = {
      layout = "us";
      xkbVariant = "altgr-intl";
    };

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      listenAddresses = [
        {
          port = 22;
          addr = "0.0.0.0";
        }
      ];
    };

    nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      virtualHosts = {
        "stash.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "https://192.168.1.5";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
            "/.well-known/carddav" = {
              return = "301 $scheme://$host/remote.php/dav";
            };
            "/.well-known/caldav" = {
              return = "301 $scheme://$host/remote.php/dav";
            };
          };
        };

        "swatrix.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "~ ^(/_matrix|/_synapse/client)" = {
              proxyPass = "http://127.0.0.1:8008";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };

        "sound.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:4040";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_redirect          http:// https://;
                proxy_read_timeout      600s;
                proxy_send_timeout      600s;
                proxy_buffering         off;
                proxy_request_buffering off;
                client_max_body_size    0;
              '';
            };
          };
        };

        "scan.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:28981";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };

        "screen.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8096";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };

        "scroll.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8080";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };

    kavita = {
      enable = true;
      user = "kavita";
      port = 8080;
      tokenKeyFile = config.sops.secrets.kavita.path;
    };

    jellyfin = {
      enable = true;
      user = "jellyfin";
    };

    radarr = {
      enable = true;
    };
    readarr = {
      enable = true;
    };
    sonarr = {
      enable = true;
    };
    lidarr = {
      enable = true;
    };
    prowlarr = {
      enable = true;
    };
    openvpn.servers = {
      pia = {
        autoStart = true;
        updateResolvConf = false;
        config = "config ${config.sops.templates.vpn.path}";
      };
    };
    transmission = {
      enable = true;
      credentialsFile = config.sops.templates."transmission-rpc".path;
      user = "vpn";
      settings = {
        alt-speed-down = 8000;
        alt-speed-enabled = false;
        alt-speed-time-begin = 0;
        alt-speed-time-day = 127;
        alt-speed-time-enabled = true;
        alt-speed-time-end = 360;
        alt-speed-up = 2000;
        bind-address-ipv4 = "0.0.0.0";
        bind-address-ipv6 = "::";
        blocklist-enabled = false;
        blocklist-url = "http://www.example.com/blocklist";
        cache-size-mb = 256;
        dht-enabled = false;
        download-dir = "/test";
        download-limit = 100;
        download-limit-enabled = 0;
        download-queue-enabled = true;
        download-queue-size = 5;
        encryption = 2;
        idle-seeding-limit = 30;
        idle-seeding-limit-enabled = false;
        incomplete-dir = "/var/lib/transmission-daemon/Downloads";
        incomplete-dir-enabled = false;
        lpd-enabled = false;
        max-peers-global = 200;
        message-level = 1;
        peer-congestion-algorithm = "";
        peer-id-ttl-hours = 6;
        peer-limit-global = 100;
        peer-limit-per-torrent = 40;
        peer-port = 22371;
        peer-port-random-high = 65535;
        peer-port-random-low = 49152;
        peer-port-random-on-start = false;
        peer-socket-tos = "default";
        pex-enabled = false;
        port-forwarding-enabled = false;
        preallocation = 1;
        prefetch-enabled = true;
        queue-stalled-enabled = true;
        queue-stalled-minutes = 30;
        ratio-limit = 2;
        ratio-limit-enabled = false;
        rename-partial-files = true;
        rpc-authentication-required = true;
        rpc-bind-address = "0.0.0.0";
        rpc-enabled = true;
        rpc-host-whitelist = "";
        rpc-host-whitelist-enabled = true;
        rpc-port = 9091;
        rpc-url = "/transmission/";
        rpc-whitelist = "127.0.0.1,192.168.3.2";
        rpc-whitelist-enabled = true;
        scrape-paused-torrents-enabled = true;
        script-torrent-done-enabled = false;
        seed-queue-enabled = false;
        seed-queue-size = 10;
        speed-limit-down = 6000;
        speed-limit-down-enabled = true;
        speed-limit-up = 500;
        speed-limit-up-enabled = true;
        start-added-torrents = true;
        trash-original-torrent-files = false;
        umask = 2;
        upload-limit = 100;
        upload-limit-enabled = 0;
        upload-slots-per-torrent = 14;
        utp-enabled = false;
      };
    };

    # sops.secrets.matrixsharedsecret = {owner="matrix-synapse";};
    # sops.templates."matrix_user_register.sh".content = ''
    # register_new_matrix_user -k ${config.sops.placeholder.matrixsharedsecret} http://localhost:8008
    # '';
    # sops.templates.matrixshared.owner = "matrix-synapse";
    # sops.templates.matrixshared.content = ''
    # registration_shared_secret: ${config.sops.placeholder.matrixsharedsecret}
    # '';
    # sops.secrets.mautrixtelegram_as = {owner="matrix-synapse";};
    # sops.secrets.mautrixtelegram_hs = {owner="matrix-synapse";};
    # sops.secrets.mautrixtelegram_api_id = {owner="matrix-synapse";};
    # sops.secrets.mautrixtelegram_api_hash = {owner="matrix-synapse";};
    # sops.templates.mautrixtelegram.owner = "matrix-synapse";
    # sops.templates.mautrixtelegram.content = ''
    # MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=${config.sops.placeholder.mautrixtelegram_as}
    # MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=${config.sops.placeholder.mautrixtelegram_hs}
    # MAUTRIX_TELEGRAM_TELEGRAM_API_ID=${config.sops.placeholder.mautrixtelegram_api_id}
    # MAUTRIX_TELEGRAM_TELEGRAM_API_HASH=${config.sops.placeholder.mautrixtelegram_api_hash}
    # '';

    # ----------------
    # sops.secrets.mautrixwhatsapp_shared = {owner="matrix-synapse";};
    # sops.templates.mautrixwhatsapp.owner = "matrix-synapse";
    # sops.templates.mautrixwhatsapp.content = ''
    # MAUTRIX_WHATSAPP_BRIDGE_LOGIN_SHARED_SECRET=${config.sops.placeholder.mautrixwhatsapp_shared}
    # '';

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
      settings.app_service_config_files = [
        "/var/lib/matrix-synapse/telegram-registration.yaml"
        "/var/lib/matrix-synapse/whatsapp-registration.yaml"
        "/var/lib/matrix-synapse/signal-registration.yaml"
        "/var/lib/matrix-synapse/doublepuppet.yaml"
      ];
      enable = false;
      settings.server_name = matrixDomain;
      settings.public_baseurl = "https://${matrixDomain}";
      extraConfigFiles = [
        config.sops.templates.matrixshared.path
      ];
      settings.listeners = [
        {
          port = 8008;
          bind_addresses = ["0.0.0.0"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
              compress = true;
            }
          ];
        }
      ];
    };

    mautrix-telegram = {
      enable = false;
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
          # login_shared_secret_map = {
          # matrixDomain = "as_token:doublepuppet";
          # };
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
      enable = false;
      # environmentFile = config.sops.templates.mautrixwhatsapp.path;
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

    mautrix-signal = {
      enable = false;
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

    navidrome = {
      enable = true;
      settings = {
        Address = "0.0.0.0";
        Port = 4040;
        MusicFolder = "/mnt/";
        EnableSharing = true;
        EnableTranscodingConfig = true;
        Scanner.GroupAlbumReleases = true;
        ScanSchedule = "@every 24h";
        # Insert these values locally as sops-nix does not work for them
        # LastFM.ApiKey = TEMPLATE;
        # LastFM.Secret = TEMPLATE;
        # Spotify.ID = TEMPLATE;
        # Spotify.Secret = TEMPLATE;
        UILoginBackgroundUrl = "https://i.imgur.com/OMLxi7l.png";
        UIWelcomeMessage = "~SwarselSound~";
      };
    };
    mpd = {
      enable = true;
      musicDirectory = "/mnt/Eternor/Musik";
      user = "mpd";
      group = "mpd";
      network = {
        port = 3254;
        listenAddress = "any";
      };
      credentials = [
        {
          passwordFile = config.sops.secrets.mpdpass.path;
          permissions = [
            "read"
            "add"
            "control"
            "admin"
          ];
        }
      ];
    };

    spotifyd = {
      enable = true;
      settings = {
        global = {
          dbus_type = "session";
          use_mpris = false;
          device = "default:CARD=PCH";
          device_name = "SwarselSpot";
          mixer = "alsa";
          zeroconf_port = 1025;
        };
      };
    };

    # Network shares
    # add a user with sudo smbpasswd -a <user>
    samba = {
      package = pkgs.samba4Full;
      extraConfig = ''
        workgroup = WORKGROUP
        server role = standalone server
        dns proxy = no

        pam password change = yes
        map to guest = bad user
        create mask = 0664
        force create mode = 0664
        directory mask = 0775
        force directory mode = 0775
        follow symlinks = yes
      '';

      # ^^ `samba4Full` is compiled with avahi, ldap, AD etc support compared to the default package, `samba`
      # Required for samba to register mDNS records for auto discovery
      # See https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/pkgs/top-level/all-packages.nix#L27268
      enable = true;
      # openFirewall = true;
      shares.test = {
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        path = "/test2";
        writable = "true";
        comment = "Eternor";
        "valid users" = "@smbtest2";
      };
    };

    avahi = {
      publish.enable = true;
      publish.userServices = true;
      # ^^ Needed to allow samba to automatically register mDNS records without the need for an `extraServiceFile`
      nssmdns = true;
      # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
      enable = true;
    };

    samba-wsdd = {
      # This enables autodiscovery on windows since SMB1 (and thus netbios) support was discontinued
      enable = true;
    };
  };
}
