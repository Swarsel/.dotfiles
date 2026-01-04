{ inputs, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "hydra"; port = 8002; }) serviceName servicePort serviceUser serviceGroup serviceAddress serviceDomain proxyAddress4 proxyAddress6 isHome isProxied homeProxy webProxy dnsServer homeProxyIf webProxyIf;
  inherit (config.swarselsystems) sopsFile;
in
{
  options = {
    swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  };
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    nodes.${dnsServer}.swarselsystems.server.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome;
      };
    };

    sops = {
      secrets = {
        nixbuild-net-key = { mode = "0600"; };
        hydra-pw = { inherit sopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
      };
      templates = {
        "hydra-env" = {
          content = ''
            HYDRA_PW="${config.sops.placeholder.hydra-pw}"
          '';
          owner = serviceUser;
          group = serviceGroup;
          mode = "0440";
        };
      };
    };

    services.hydra = {
      enable = true;
      package = inputs.hydra.packages.${config.node.arch}.hydra;
      port = servicePort;
      hydraURL = "https://${serviceDomain}";
      listenHost = "*";
      notificationSender = "hydra@${globals.domains.main}";
      minimumDiskFreeEvaluator = 20; # 20G
      minimumDiskFree = 20; # 20G
      useSubstitutes = true;
      smtpHost = globals.services.mailserver.domain;
      buildMachinesFiles = [
        "/etc/nix/machines"
      ];
      extraConfig = ''
        using_frontend_proxy 1
      '';
    };

    systemd.services.hydra-user-setup = {
      description = "Create admin user for Hydra";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "hydra";
        EnvironmentFile = [
          config.sops.templates.hydra-env.path
        ];
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "hydra-init.service" ];
      after = [ "hydra-init.service" ];
      environment = lib.mkForce config.systemd.services.hydra-init.environment;
      script = ''
          set -eu
        if [ ! -e ~hydra/.user-setup-done ]; then
          /run/current-system/sw/bin/hydra-create-user admin --full-name 'admin' --email-address 'admin@${globals.domains.main}' --password "$HYDRA_PW" --role admin
          touch ~hydra/.user-setup-done
        fi
      '';
    };

    environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
    ];

    nix = {
      settings.builders-use-substitutes = true;
      distributedBuilds = true;
      buildMachines = [
        {
          hostName = "localhost";
          protocol = null;
          system = config.node.arch;
          supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
          maxJobs = 4;
        }
      ];
    };

    # networking.firewall.allowedTCPPorts = [ servicePort ];

    programs.ssh = {
      extraConfig = ''
        StrictHostKeyChecking no
      '';
    };

    nodes.${webProxy}.services.nginx = {
      upstreams = {
        ${serviceName} = {
          servers = {
            "${serviceAddress}:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          oauth2.enable = false;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                  client_max_body_size 0;
                proxy_set_header  X-Request-Base    /hydra;
              '';
            };
          };
        };
      };
    };

  };
}
