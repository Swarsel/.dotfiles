{
  self,
  lib,
  config,
  pkgs,
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

  options.sandbox.tlsDomains = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config = {
    sandbox.tlsDomains = [
      globals.services.kanidm.domain
      globals.services.oauth2-proxy.domain
    ];

    swarselsystems = {
      isLinux = true;
      isPublic = true;
      nodeRoles = [
        "webProxy"
        "oauthServer"
      ];
    };

    repo.secretFiles = {
      common = lib.mkForce ./secrets/pii.nix;
      local = ./secrets/pii-local.nix;
    };

    sops = {
      age = {
        sshKeyPaths = lib.mkForce [ ];
        keyFile = "/var/lib/sops-nix/key.txt";
      };

      secrets = {
        kanidm-self-signed-crt.sopsFile = lib.mkForce config.swarselsystems.sopsFile;
        kanidm-self-signed-key.sopsFile = lib.mkForce config.swarselsystems.sopsFile;
        kanidm-oauth2-proxy = {
          owner = lib.mkForce "kanidm";
          group = lib.mkForce "kanidm";
          mode = lib.mkForce "0440";
        };
      };

      templates.motd = {
        mode = "0444";
        content = ''

          vacanthouse sandbox
          ===================
          kanidm idm_admin password: ${config.sops.placeholder.kanidm-idm-admin-pw}

          set a credential for the sandbox person:
            kanidm login -D idm_admin
            kanidm person credential create-reset-token sandbox

        '';
      };
    };

    system.activationScripts = {
      sandboxAgeKey.text = ''
        install -d -m 700 /var/lib/sops-nix
        install -m 600 ${../../../files/public/age/vacanthouse.key} /var/lib/sops-nix/key.txt
      '';
      setupSecrets.deps = [ "sandboxAgeKey" ];
    };

    networking = {
      hosts."127.0.0.1" = config.sandbox.tlsDomains;
      firewall.allowedTCPPorts = [ 8300 ];
    };

    services.nginx.virtualHosts = lib.genAttrs config.sandbox.tlsDomains (_: {
      useACMEHost = lib.mkForce null;
      sslCertificate = "${../../../files/public/certs/wildcard.crt}";
      sslCertificateKey = "${../../../files/public/certs/wildcard.key}";
    });

    security.pki.certificateFiles = [ ../../../files/public/certs/ca.crt ];

    users.motdFile = config.sops.templates.motd.path;

    services.kanidm.provision = {
      groups."sandbox.access".members = [ "sandbox" ];
      systems.oauth2.oauth2-proxy = {
        scopeMaps."sandbox.access" = [
          "openid"
          "email"
          "profile"
        ];
        claimMaps.groups.valuesByGroup."sandbox.access" = [ "sandbox_access" ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /etc/ssl/private 0755 root root -"
      "C+ /etc/ssl/certs/kanidm.crt 0644 kanidm kanidm - ${../../../files/public/certs/wildcard.crt}"
      "C+ /etc/ssl/private/kanidm.key 0600 kanidm kanidm - ${../../../files/public/certs/wildcard.key}"
      "C /root/.bash_history 0600 root root - ${pkgs.writeText "sandbox-seed-history" ''
        cat /run/secrets/kanidm-idm-admin-pw
        kanidm login -D idm_admin
        kanidm person credential create-reset-token sandbox
      ''}"
    ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    boot.loader.grub.enable = false;

    system.stateVersion = "24.11";

    virtualisation.vmVariant.virtualisation = {
      cores = 2;
      memorySize = 4096;
      graphics = false;
      forwardPorts = [
        {
          from = "host";
          host.port = 80;
          guest.port = 80;
        }
        {
          from = "host";
          host.port = 443;
          guest.port = 443;
        }
        {
          from = "host";
          host.port = 8300;
          guest.port = 8300;
        }
      ];
    };
  };
}
