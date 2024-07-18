{
  config,
  pkgs,
  ...
}: {
  imports = [
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

  sops = {
    age.sshKeyPaths = ["/etc/ssh/sops"];
    defaultSopsFile = "/root/.dotfiles/secrets/sync/secrets.yaml";
    validateSopsFiles = false;
    secrets.swarsel = {owner = "root";};
    secrets.dnstokenfull = {owner = "acme";};
    templates."certs.secret".content = ''
      CF_DNS_API_TOKEN=${config.sops.placeholder.dnstokenfull}
    '';
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
      "synki.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations = {
          "/" = {
            proxyPass = "http://localhost:27701";
            extraConfig = ''
              client_max_body_size 0;
            '';
          };
        };
      };

      "sync.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8384/";
            extraConfig = ''
              client_max_body_size 0;
            '';
          };
        };
      };

      "swagit.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations = {
          "/" = {
            proxyPass = "http://localhost:3000";
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
    hostName = "sync";
    enableIPv6 = false;
    domain = "subnet03112148.vcn03112148.oraclevcn.com";
    firewall.extraCommands = ''
      iptables -I INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 27701 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 8384 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 3000 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p tcp --dport 22000 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p udp --dport 22000 -j ACCEPT
      iptables -I INPUT -m state --state NEW -p udp --dport 21027 -j ACCEPT
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

  services.anki-sync-server = {
    enable = true;
    port = 27701;
    address = "0.0.0.0";
    openFirewall = true;
    users = [
      {
        username = "Swarsel";
        passwordFile = config.sops.secrets.swarsel.path;
      }
    ];
  };

  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    openDefaultPorts = true;
  };

  services.forgejo = {
    enable = true;
    settings = {
      DEFAULT = {
        APP_NAME = "~SwaGit~";
      };
      server = {
        PROTOCOL = "http";
        HTTP_PORT = 3000;
        HTTP_ADDR = "0.0.0.0";
        DOMAIN = "swagit.swarsel.win";
        ROOT_URL = "https://swagit.swarsel.win";
      };
      service = {
        DISABLE_REGISTRATION = true;
        SHOW_REGISTRATION_BUTTON = false;
      };
    };
  };
}
