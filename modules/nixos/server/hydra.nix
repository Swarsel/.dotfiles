{ inputs, lib, config, globals, confLib, ... }:
let
  inherit (confLib.gen { name = "hydra"; port = 8002; }) serviceName servicePort serviceUser serviceGroup serviceAddress serviceDomain proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy homeProxyIf webProxyIf homeServiceAddress nginxAccessRules;
  inherit (config.swarselsystems) sopsFile;
in
{
  config = {
    swarselsystems.enabledServerModules = [ "hydra" ];

    topology.self.services.${serviceName}.info = "https://${serviceDomain}";

    globals = {
      networks = {
        ${webProxyIf}.hosts = lib.mkIf isProxied {
          ${config.node.name}.firewallRuleForNode.${webProxy}.allowedTCPPorts = [ servicePort ];
        };
        ${homeProxyIf}.hosts = lib.mkIf isHome {
          ${config.node.name}.firewallRuleForNode.${homeWebProxy}.allowedTCPPorts = [ servicePort ];
        };
      };
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/";
        network = "local-${config.node.name}";
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


    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes =
      let
        extraConfigLoc = ''
          proxy_set_header  X-Request-Base    /hydra;
        '';
      in
      {
        ${webProxy}.services.nginx = confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; };
        ${homeWebProxy}.services.nginx = lib.mkIf isHome (confLib.genNginx { inherit servicePort serviceDomain serviceName extraConfigLoc; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; });
      };

  };
}
