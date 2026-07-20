{
  flake-file.inputs = {
    hydra = {
      inputs.nix-eval-jobs.follows = "nix-eval-jobs";
      url = "github:nixos/hydra/nix-2.30";
    };

    nix-eval-jobs = {
      flake = false;
      url = "github:nix-community/nix-eval-jobs";
    };
  };

  flake.modules.nixos.hydra =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? hydra) [
        (
          {
            inputs,
            config,
            lib,
            confLib,
            globals,
            ...
          }:
          let
            inherit
              (confLib.gen {
                name = "hydra";
                port = 8002;
              })
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceGroup
              serviceName
              servicePort
              serviceUser
              ;
            inherit (confLib.static)
              homeServiceAddress
              homeWebProxy
              isHome
              nginxAccessRules
              webProxy
              ;
            inherit (config.swarselsystems) sopsFile;
          in
          {
            swarselsystems.enabledServerModules = [ "hydra" ];
            topology.self.services.${serviceName}.info = "https://${serviceDomain}";
            globals = {
              services = confLib.mkServiceGlobal {
                inherit
                  homeServiceAddress
                  isHome
                  proxyAddress4
                  proxyAddress6
                  serviceAddress
                  serviceDomain
                  serviceName
                  ;
              };
              dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
              monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; };
              networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
            };
            sops = {
              secrets = {
                hydra-pw = {
                  inherit sopsFile;
                  group = serviceGroup;
                  mode = "0440";
                  owner = serviceUser;
                };
                nixbuild-net-key.mode = "0600";
              };
              templates."hydra-env" = {
                content = ''
                  HYDRA_PW="${config.sops.placeholder.hydra-pw}"
                '';
                group = serviceGroup;
                mode = "0440";
                owner = serviceUser;
              };
            };
            services.hydra = {
              enable = true;
              package = inputs.hydra.packages.${config.node.arch}.hydra;
              buildMachinesFiles = [
                "/etc/nix/machines"
              ];
              extraConfig = ''
                using_frontend_proxy 1
              '';
              hydraURL = "https://${serviceDomain}";
              listenHost = "*";
              minimumDiskFree = 20; # 20G
              minimumDiskFreeEvaluator = 20; # 20G
              notificationSender = "hydra@${globals.domains.main}";
              port = servicePort;
              smtpHost = globals.services.mailserver.domain;
              useSubstitutes = true;
            };
            # networking.firewall.allowedTCPPorts = [ servicePort ];
            programs.ssh.extraConfig = ''
              StrictHostKeyChecking no
            '';
            environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
            ];
            nix = {
              buildMachines = [
                {
                  hostName = "localhost";
                  maxJobs = 4;
                  protocol = null;
                  supportedFeatures = [
                    "kvm"
                    "nixos-test"
                    "big-parallel"
                    "benchmark"
                  ];
                  system = config.node.arch;
                }
              ];
              distributedBuilds = true;
              settings.builders-use-substitutes = true;
            };
            systemd.services.hydra-user-setup = {
              after = [ "hydra-init.service" ];
              description = "Create admin user for Hydra";
              environment = lib.mkForce config.systemd.services.hydra-init.environment;
              requires = [ "hydra-init.service" ];
              script = ''
                  set -eu
                if [ ! -e ~hydra/.user-setup-done ]; then
                  /run/current-system/sw/bin/hydra-create-user admin --full-name 'admin' --email-address 'admin@${globals.domains.main}' --password "$HYDRA_PW" --role admin
                  touch ~hydra/.user-setup-done
                fi
              '';
              serviceConfig = {
                EnvironmentFile = [
                  config.sops.templates.hydra-env.path
                ];
                RemainAfterExit = true;
                Type = "oneshot";
                User = "hydra";
              };
              wantedBy = [ "multi-user.target" ];
            };
            nodes =
              let
                extraConfigLoc = ''
                  proxy_set_header  X-Request-Base    /hydra;
                '';
              in
              lib.mkMerge [
                {
                  ${webProxy}.services.nginx = confLib.genNginx {
                    inherit
                      extraConfigLoc
                      serviceAddress
                      serviceDomain
                      serviceName
                      servicePort
                      ;
                    maxBody = 0;
                  };
                }
                {
                  ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                    confLib.genNginx {
                      inherit
                        extraConfigLoc
                        serviceDomain
                        serviceName
                        servicePort
                        ;
                      extraConfig = nginxAccessRules;
                      maxBody = 0;
                      serviceAddress = homeServiceAddress;
                    }
                  );
                }
              ];
          }
        )
      ];
    };
}
