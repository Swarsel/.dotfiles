{
  self,
  config,
  lib,
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
    default = [ ];
    type = lib.types.listOf lib.types.str;
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

      secrets = {
        kanidm-oauth2-proxy = {
          group = lib.mkForce "kanidm";
          mode = lib.mkForce "0440";
          owner = lib.mkForce "kanidm";
        };
        kanidm-self-signed-crt.sopsFile = lib.mkForce config.swarselsystems.sopsFile;
        kanidm-self-signed-key.sopsFile = lib.mkForce config.swarselsystems.sopsFile;
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
    services = {
      kanidm.provision = {
        groups."sandbox.access".members = [ "sandbox" ];
        systems.oauth2.oauth2-proxy = {
          claimMaps.groups.valuesByGroup."sandbox.access" = [ "sandbox_access" ];
          scopeMaps."sandbox.access" = [
            "openid"
            "email"
            "profile"
          ];
        };
      };
      nginx.virtualHosts = lib.genAttrs config.sandbox.tlsDomains (_: {
        sslCertificate = "${../../../files/public/certs/wildcard.crt}";
        sslCertificateKey = "${../../../files/public/certs/wildcard.key}";
        useACMEHost = lib.mkForce null;
      });
    };
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
    security.pki.certificateFiles = [ ../../../files/public/certs/ca.crt ];
    system = {
      activationScripts = {
        sandboxAgeKey.text = ''
          install -d -m 700 /var/lib/sops-nix
          install -m 600 ${../../../files/public/age/vacanthouse.key} /var/lib/sops-nix/key.txt
        '';
        setupSecrets.deps = [ "sandboxAgeKey" ];
      };
      stateVersion = "24.11";
    };
    virtualisation.vmVariant.virtualisation = {
      cores = 2;
      forwardPorts = [
        {
          from = "host";
          guest.port = 80;
          host.port = 80;
        }
        {
          from = "host";
          guest.port = 443;
          host.port = 443;
        }
        {
          from = "host";
          guest.port = 8300;
          host.port = 8300;
        }
      ];
      graphics = false;
      memorySize = 4096;
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
  };
}
