{ config, lib, pkgs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  services.xserver = {
    xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
  };

  # nix.settings.experimental-features = ["nix-command" "flakes"];

  users.mutableUsers = false;

  environment = {
    wordlist.enable = true;
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
        gst-plugins-good
        gst-plugins-bad
        gst-plugins-ugly
        gst-libav
      ]);
    };
  };
  # gstreamer plugins for nautilus (used for file metadata)

  time.hardwareClockInLocalTime = true;

  # dont style GRUB with stylix
  stylix.targets.grub.enable = false; # the styling makes grub more ugly

  security.polkit.enable = true;

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # systemd
  systemd.extraConfig = ''
    DefaultTimeoutStartSec=60s
    DefaultTimeoutStopSec=15s
  '';

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };

    enableAllFirmware = true;

    bluetooth = {
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [
        "${config.sops.templates."network-manager.env".path}"
      ];
      profiles = {
        "Ernest Routerford" = {
          connection = {
            id = "Ernest Routerford";
            permissions = "";
            type = "wifi";
          };
          ipv4 = {
            dns-search = "";
            method = "auto";
          };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            dns-search = "";
            method = "auto";
          };
          wifi = {
            mac-address-blacklist = "";
            mode = "infrastructure";
            ssid = "Ernest Routerford";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$ERNEST";
          };
        };

        LAN-Party = {
          connection = {
            autoconnect = "false";
            id = "LAN-Party";
            type = "ethernet";
          };
          ethernet = {
            auto-negotiate = "true";
            cloned-mac-address = "preserve";
            mac-address = "90:2E:16:D0:A1:87";
          };
          ipv4 = { method = "shared"; };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
          };
          proxy = { };
        };

        eduroam = {
          "802-1x" = {
            eap = "ttls;";
            identity = "$EDUID";
            password = "$EDUPASS";
            phase2-auth = "mschapv2";
          };
          connection = {
            id = "eduroam";
            type = "wifi";
          };
          ipv4 = { method = "auto"; };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "eduroam";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-eap";
          };
        };

        local = {
          connection = {
            autoconnect = "false";
            id = "local";
            type = "ethernet";
          };
          ethernet = { };
          ipv4 = {
            address1 = "10.42.1.1/24";
            method = "shared";
          };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
          };
          proxy = { };
        };

        HH40V_39F5 = {
          connection = {
            id = "HH40V_39F5";
            type = "wifi";
          };
          ipv4 = { method = "auto"; };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
          };
          proxy = { };
          wifi = {
            band = "bg";
            mode = "infrastructure";
            ssid = "HH40V_39F5";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$FRAUNS";
          };
        };

        magicant = {
          connection = {
            id = "magicant";
            type = "wifi";
          };
          ipv4 = { method = "auto"; };
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = { };
          wifi = {
            mode = "infrastructure";
            ssid = "magicant";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$HANDYHOTSPOT";
          };
        };

        "sweden-aes-128-cbc-udp-dns" = {
          connection = {
            autoconnect = "false";
            id = "PIA Sweden";
            type = "vpn";
          };
          ipv4 = { method = "auto"; };
          ipv6 = {
            addr-gen-mode = "stable-privacy";
            method = "auto";
          };
          proxy = { };
          vpn = {
            auth = "sha1";
            ca =
              "${config.users.users.swarsel.home}/.dotfiles/secrets/certs/sweden-aes-128-cbc-udp-dns-ca.pem";
            challenge-response-flags = "2";
            cipher = "aes-128-cbc";
            compress = "yes";
            connection-type = "password";
            crl-verify-file = "${config.users.users.swarsel.home}/.dotfiles/secrets/certs/sweden-aes-128-cbc-udp-dns-crl-verify.pem";
            dev = "tun";
            password-flags = "0";
            remote = "sweden.privacy.network:1198";
            remote-cert-tls = "server";
            reneg-seconds = "0";
            service-type = "org.freedesktop.NetworkManager.openvpn";
            username = "$VPNUSER";
          };
          vpn-secrets = { password = "$VPNPASS"; };
        };

        Hotspot = {
          connection = {
            autoconnect = "false";
            id = "Hotspot";
            type = "wifi";
          };
          ipv4 = { method = "shared"; };
          ipv6 = {
            addr-gen-mode = "default";
            method = "ignore";
          };
          proxy = { };
          wifi = {
            mode = "ap";
            ssid = "Hotspot-fourside";
          };
          wifi-security = {
            group = "ccmp;";
            key-mgmt = "wpa-psk";
            pairwise = "ccmp;";
            proto = "rsn;";
            psk = "$HOTSPOT";
          };
        };

      };
    };
  };

  systemd.services.NetworkManager-ensure-profiles.after = [ "NetworkManager.service" ];

  time.timeZone = "Europe/Vienna";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_AT.UTF-8";
      LC_IDENTIFICATION = "de_AT.UTF-8";
      LC_MEASUREMENT = "de_AT.UTF-8";
      LC_MONETARY = "de_AT.UTF-8";
      LC_NAME = "de_AT.UTF-8";
      LC_NUMERIC = "de_AT.UTF-8";
      LC_PAPER = "de_AT.UTF-8";
      LC_TELEPHONE = "de_AT.UTF-8";
      LC_TIME = "de_AT.UTF-8";
    };
  };

  sops = {

    defaultSopsFile = "${config.users.users.swarsel.home}/.dotfiles/secrets/general/secrets.yaml";
    validateSopsFiles = false;

    secrets = {
      swarseluser = { neededForUsers = true; };
      ernest = { };
      frauns = { };
      hotspot = { };
      eduid = { };
      edupass = { };
      handyhotspot = { };
      vpnuser = { };
      vpnpass = { };
    };
    templates = {
      "network-manager.env".content = ''
        ERNEST=${config.sops.placeholder.ernest}
        FRAUNS=${config.sops.placeholder.frauns}
        HOTSPOT=${config.sops.placeholder.hotspot}
        EDUID=${config.sops.placeholder.eduid}
        EDUPASS=${config.sops.placeholder.edupass}
        HANDYHOTSPOT=${config.sops.placeholder.handyhotspot}
        VPNUSER=${config.sops.placeholder.vpnuser}
        VPNPASS=${config.sops.placeholder.vpnpass}
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    # yubikey packages
    gnupg
    yubikey-personalization
    yubikey-personalization-gui
    yubico-pam
    yubioath-flutter
    yubikey-manager
    yubikey-manager-qt
    yubico-piv-tool
    cfssl
    pcsctools
    pcscliteWithPolkit.out

    # ledger packages
    ledger-live-desktop

    # pinentry

    # theme related
    adwaita-icon-theme

    # kde-connect
    xdg-desktop-portal

    # bluetooth
    bluez

    # lsp-related -------------------------------
    # nix
    # latex
    texlab
    ghostscript_headless
    # wireguard
    wireguard-tools
    # rust
    rust-analyzer
    clippy
    rustfmt
    # go
    go
    gopls
    # zig
    zig
    zls
    # cpp
    clang-tools
    # + cuda
    cudatoolkit
    #lsp-bridge / python
    gcc
    gdb
    (python3.withPackages (ps: with ps; [ jupyter ipython pyqt5 epc orjson sexpdata six setuptools paramiko numpy pandas scipy matplotlib requests debugpy flake8 gnureadline python-lsp-server ]))
    # (python3.withPackages(ps: with ps; [ jupyter ipython pyqt5 numpy pandas scipy matplotlib requests debugpy flake8 gnureadline python-lsp-server]))
    # --------------------------------------------

    (stdenv.mkDerivation {
      name = "oama";

      src = pkgs.fetchurl {
        name = "oama";
        url = "https://github.com/pdobsan/oama/releases/download/0.13.1/oama-0.13.1-Linux-x86_64-static.tgz";
        sha256 = "sha256-OTdCObVfnMPhgZxVtZqehgUXtKT1iyqozdkPIV+i3Gc=";
      };

      phases = [
        "unpackPhase"
      ];

      unpackPhase = ''
        mkdir -p $out/bin
        tar xvf $src -C $out/
        mv $out/oama-0.13.1-Linux-x86_64-static/oama $out/bin/
      '';

    })

  ];

  programs = {
    dconf.enable = true;
    evince.enable = true;
    kdeconnect.enable = true;
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];
  environment.pathsToLink = [ "/share/zsh" ];

  services.syncthing = {
    enable = true;
    user = "swarsel";
    dataDir = "/home/swarsel";
    configDir = "/home/swarsel/.config/syncthing";
    openDefaultPorts = true;
    settings = {
      devices = {
        "magicant" = {
          id = "SEH2NMT-IVRQUU5-VPW2HUQ-3GQYDBF-F6H6OY6-X3DZTUZ-LCRE2DJ-QNIXIQ2";
        };
        "sync (@oracle)" = {
          id = "ETW6TST-NPK7MKZ-M4LXMHA-QUPQHDT-VTSHH5X-CR5EIN2-YU7E55F-MGT7DQB";
        };
        "server1" = {
          id = "ZXWVC4X-IIARITZ-MERZPHN-HD55Y6G-QJM2GTB-6BWYXMR-DTO3TS2-QDBREQQ";
        };
      };
      folders = {
        "Default Folder" = {
          path = "/home/swarsel/Sync";
          devices = [ "sync (@oracle)" ];
          id = "default";
        };
        "Obsidian" = {
          path = "/home/swarsel/Nextcloud/Obsidian";
          devices = [ "sync (@oracle)" ];
          id = "yjvni-9eaa7";
        };
        "Org" = {
          path = "/home/swarsel/Nextcloud/Org";
          devices = [ "sync (@oracle)" ];
          id = "a7xnl-zjj3d";
        };
        "Vpn" = {
          path = "/home/swarsel/Vpn";
          devices = [ "sync (@oracle)" ];
          id = "hgp9s-fyq3p";
        };
      };
    };
  };

  services.blueman.enable = true;

  # enable scanners over network
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  # enable discovery and usage of network devices (esp. printers)
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
      pkgs.gutenprintBin
    ];
    browsedConf = ''
      BrowseDNSSDSubTypes _cups,_print
      BrowseLocalProtocols all
      BrowseRemoteProtocols all
      CreateIPPPrinterQueues All
      BrowseProtocols all
    '';
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.gvfs.enable = true;

  # Make CAPS work as a dual function ESC/CTRL key
  services.interception-tools = {
    enable = true;
    udevmonConfig =
      let
        dualFunctionKeysConfig = builtins.toFile "dual-function-keys.yaml" ''
          TIMING:
            TAP_MILLISEC: 200
            DOUBLE_TAP_MILLISEC: 0

          MAPPINGS:
            - KEY: KEY_CAPSLOCK
              TAP: KEY_ESC
              HOLD: KEY_LEFTCTRL
        '';
      in
      ''
        - JOB: |
            ${pkgs.interception-tools}/bin/intercept -g $DEVNODE \
              | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dualFunctionKeysConfig} \
              | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE
          DEVICE:
            EVENTS:
              EV_KEY: [KEY_CAPSLOCK]
      '';
  };

  programs.ssh.startAgent = false;

  services.pcscd.enable = true;

  hardware.ledger.enable = true;

  services.udev.packages = with pkgs; [
    yubikey-personalization
    ledger-udev-rules
  ];

  services.greetd = {
    enable = true;
    settings = {
      initial_session.command = "sway";
      # initial_session.user ="swarsel";
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time \
          --asterisks \
          --user-menu \
          --cmd sway
      '';
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
  '';

}
