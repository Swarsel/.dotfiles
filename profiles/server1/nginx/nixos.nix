{ pkgs, modulesPath, ... }:

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

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "stash.swarsel.win" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/" = {
            proxyPass = "https://192.168.2.5";
            extraConfig = ''
            proxy_read_timeout 36000s;
            proxy_http_version 1.1;
            proxy_buffering off;
            client_max_body_size 0;
            proxy_redirect off;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X_Forwarded_For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_hide_header X-Powered-By;
            proxy_pass_header Authorization;
            '';
          };
          "/push/" = {
            proxyPass = "http://192.168.2.5:7867";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
              proxy_set_header Host $host;
              proxy_set_header X_Forwarded_For $proxy_add_x_forwarded_for;
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

        "sound.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "https://192.168.2.13";
              extraConfig = ''
                proxy_read_timeout 36000s;
                proxy_http_version 1.1;
                proxy_buffering off;
                client_max_body_size 0;
                proxy_redirect off;
                proxy_set_header Connection "";
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X_Forwarded_For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_hide_header X-Powered-By;
                proxy_hide_header X-Frame-Options;
                proxy_pass_header Authorization;
              '';
            };
          };
        };
      };
    };





}
