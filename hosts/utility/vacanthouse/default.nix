{
  self,
  config,
  lib,
  pkgs,
  confLib,
  globals,
  ...
}:
{
  imports = [
    self.modules.generic.meta
    self.modules.generic.options
    self.modules.generic.globals
    self.modules.generic.config-lib
    self.modules.generic.pii
    self.modules.nixos.nodes
    self.modules.nixos.node-roles
    self.modules.nixos.nftables
    self.modules.nixos.id
    self.modules.nixos.impermanence
    self.modules.nixos.topology
    self.modules.nixos.sops
    self.modules.nixos.users
    self.modules.nixos.nginx
    self.modules.nixos.kanidm
    self.modules.nixos.oauth2-proxy
    ./sandbox.nix
  ];

  options.sandbox = {
    tls = {
      ca = lib.mkOption {
        default = ../../../files/public/certs/ca.crt;
        type = lib.types.path;
      };
      certificate = lib.mkOption {
        default = ../../../files/public/certs/wildcard.crt;
        type = lib.types.path;
      };
      keyFile = lib.mkOption {
        default = "/mnt/sandbox-tls/wildcard.key";
        type = lib.types.str;
      };
    };
    tlsDomains = lib.mkOption {
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };

  config = {
    swarselsystems = {
      isLinux = true;
      isPublic = true;
      nodeRoles = [
        "webProxy"
        "oauthServer"
      ];
    };
    sops = {
      age = {
        keyFile = "/var/lib/sops-nix/key.txt";
        sshKeyPaths = lib.mkForce [ ];
      };

      secrets.kanidm-oauth2-proxy = {
        group = lib.mkForce "kanidm";
        mode = lib.mkForce "0440";
        owner = lib.mkForce "kanidm";
      };

      templates.motd = {
        content = ''

          vacanthouse sandbox
          ===================
          kanidm idm_admin password: ${config.sops.placeholder.kanidm-idm-admin-pw}

          set a credential for the sandbox person:
            kanidm login -D idm_admin
            kanidm person credential create-reset-token sandbox

        '';
        mode = "0444";
      };
    };
    users.motdFile = config.sops.templates.motd.path;
    services = lib.mkMerge [
      (confLib.mkKanidmOauth2ProxyAccess { serviceName = "sandbox"; }).services
      {
        kanidm.provision.groups."sandbox.access".members = [ "sandbox" ];
        nginx.virtualHosts = lib.genAttrs config.sandbox.tlsDomains (_: {
          sslCertificate = "${config.sandbox.tls.certificate}";
          sslCertificateKey = "/run/sandbox-tls/nginx.key";
          useACMEHost = lib.mkForce null;
        });
      }
    ];
    boot.loader.grub.enable = false;
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    networking = {
      firewall.allowedTCPPorts = [ 8300 ];
      hosts."127.0.0.1" = config.sandbox.tlsDomains;
    };
    repo.secretFiles = {
      common = lib.mkForce ./secrets/pii.nix;
      local = ./secrets/pii-local.nix;
    };
    sandbox.tlsDomains = [
      globals.services.kanidm.domain
      globals.services.oauth2-proxy.domain
    ];
    security.pki.certificateFiles = [ config.sandbox.tls.ca ];
    system = {
      activationScripts = {
        sandboxAgeKey.text = ''
          install -d -m 700 /var/lib/sops-nix
          install -m 600 ${../../../files/public/age/hosts/vacanthouse.key} /var/lib/sops-nix/key.txt
        '';
        setupSecrets.deps = [ "sandboxAgeKey" ];
      };
      stateVersion = "24.11";
    };
    virtualisation.vmVariant.virtualisation = {
      cores = 2;
      forwardPorts =
        map
          (port: {
            from = "host";
            guest.port = port;
            host.port = port;
          })
          [
            80
            443
            8300
          ];
      graphics = false;
      memorySize = 4096;
      sharedDirectories.sandbox-tls = {
        source = "/run/sandbox-tls";
        target = "/mnt/sandbox-tls";
      };
    };
    systemd = {
      services.sandbox-tls = {
        before = [
          "kanidm.service"
          "nginx.service"
        ];
        requiredBy = [
          "kanidm.service"
          "nginx.service"
        ];
        script = ''
          install -d -m 0755 /run/sandbox-tls /etc/ssl/private
          install -m 0400 -o nginx -g nginx ${config.sandbox.tls.keyFile} /run/sandbox-tls/nginx.key
          install -m 0600 -o kanidm -g kanidm ${config.sandbox.tls.keyFile} /etc/ssl/private/kanidm.key
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
        unitConfig.RequiresMountsFor = [ config.sandbox.tls.keyFile ];
      };
      tmpfiles.rules = [
        "C+ /etc/ssl/certs/kanidm.crt 0644 kanidm kanidm - ${config.sandbox.tls.certificate}"
        "C /root/.bash_history 0600 root root - ${pkgs.writeText "sandbox-seed-history" ''
          cat /run/secrets/kanidm-idm-admin-pw
          kanidm login -D idm_admin
          kanidm person credential create-reset-token sandbox
        ''}"
      ];
    };
  };
}
