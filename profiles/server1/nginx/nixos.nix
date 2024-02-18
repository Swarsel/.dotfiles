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
    lego
    nginx
  ];

  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  sops.age.sshKeyPaths = [ "/etc/ssh/sops" ];
  sops.defaultSopsFile = "/.dotfiles/secrets/nginx/secrets.yaml";
  sops.validateSopsFiles = false;
  sops.secrets.dnstokenfull = {owner="acme";};
  sops.templates."certs.secret".content = ''
  CF_DNS_API_TOKEN=${config.sops.placeholder.dnstokenfull}
  '';
  proxmoxLXC.manageNetwork = true; # manage network myself
  proxmoxLXC.manageHostName = false; # manage hostname myself
  networking.hostName = "nginx"; # Define your hostname.
  networking.useDHCP = true;
  networking.enableIPv6 = false;
  networking.firewall.enable = false;
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/keys/authorized_keys
  ];
  # users.users.root.password = "TEMPLATE";

  system.stateVersion = "23.05"; # TEMPLATE - but probably no need to change

  security.acme = {
    acceptTerms = true;
    preliminarySelfsigned = false;
    defaults.email = "mrswarsel@gmail.com";
    defaults.dnsProvider = "cloudflare";
    defaults.environmentFile = "${config.sops.templates."certs.secret".path}";
  };

  environment.shellAliases = {
    nswitch = "cd /.dotfiles; git pull; nixos-rebuild --flake .#$(hostname) switch; cd -;";
  };

  services.nginx = {
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
          # "/push/" = {
            # proxyPass = "http://192.168.2.5:7867";
          # };
          "/.well-known/carddav" = {
            return = "301 $scheme://$host/remote.php/dav";
          };
          "/.well-known/caldav" = {
            return = "301 $scheme://$host/remote.php/dav";
          };
        };
      };

      "matrix2.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        acmeRoot = null;
        locations = {
          "~ ^(/_matrix|/_synapse/client)" = {
            proxyPass = "http://192.168.1.23:8008";
            extraConfig = ''
                client_max_body_size 0;
              '';
          };
        };
      };

        # "sound.swarsel.win" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   acmeRoot = null;
        #   locations = {
        #     "/" = {
        #       proxyPass = "https://192.168.2.13";
        #       extraConfig = ''
        #         client_max_body_size 0;
        #       '';
        #     };
        #   };
        # };

    #     "sound.swarsel.win" = {
    #       enableACME = true;
    #       forceSSL = true;
    #       acmeRoot = null;
    #       locations = {
    #         "/" = {
    #           proxyPass = "http://192.168.2.13:4040";
    #       recommendedProxySettings = false;
    #           # proxyWebsockets = true;
    #           extraConfig = ''
    # proxy_set_header Upgrade           $http_upgrade;
    # proxy_set_header Connection        "Upgrade";
    # proxy_set_header X-Real-IP         $remote_addr;
    # proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    # proxy_set_header X-Forwarded-Proto https;
    # proxy_set_header X-Forwarded-Host  $host;
    # proxy_set_header X-Forwarded-Port  $server_port;
    # proxy_set_header Host              $host;
    # proxy_max_temp_file_size           0;
    # proxy_redirect                     http:// https://;
    # proxy_buffering off;
    # proxy_request_buffering off;
    # client_max_body_size    0;
    #           '';
    #         };
    #       };
        # };

        "sound.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://192.168.1.13:4040";
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
              proxyPass = "http://192.168.1.24:28981";
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
              proxyPass = "http://192.168.1.16:8096";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };

        "matrix.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "~ ^(/_matrix|/_synapse/client)" = {
              proxyPass = "http://192.168.1.20:8008";
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
              proxyPass = "http://192.168.1.22:8080";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };

        # "books.swarsel.win" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   acmeRoot = null;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://192.168.2.22:8083";
        #       extraConfig = ''
        #         client_max_body_size 0;
        #       '';
        #     };
        #   };
        # };

        "blog.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "https://192.168.1.7";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };

      };
    };





}
