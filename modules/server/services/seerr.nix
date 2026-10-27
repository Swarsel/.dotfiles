{
  flake-file.inputs.seerr-oidc = {
    flake = false;
    url = "github:michaelhthomas/seerr/feat/oidc-login-basic";
  };

  flake.modules.nixos.seerr =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? seerr-oidc) [
        (
          {
            self,
            inputs,
            config,
            lib,
            pkgs,
            confLib,
            ...
          }:
          let
            inherit
              (confLib.gen {
                dir = "/var/lib/private/jellyseerr";
                name = "seerr";
                port = 5055;
              })
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDir
              serviceDomain
              serviceName
              servicePort
              ;
            inherit (confLib.static)
              homeServiceAddress
              homeWebProxy
              idmServer
              isHome
              nginxAccessRules
              webProxy
              ;
            kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
          in
          {
            swarselsystems.enabledServerModules = [ "seerr" ];
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
                extra.extraConfig.node = config.node.name;
              };
              dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
              monitoring.http = confLib.mkHttpMonitoring {
                inherit serviceName servicePort;
                expectedBodyRegex = "version";
                path = "/api/v1/status";
              };
              networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
            };

            sops.secrets.kanidm-seerr.sopsFile = kanidmSopsFile;
            services.${serviceName} = {
              enable = true;
              package = pkgs.seerr.overrideAttrs (old: {
                pnpmDeps = old.pnpmDeps.overrideAttrs {
                  outputHash = "sha256-bfdmNLBypcoJ79/lMRSgRKSIddQJJohcn3/dL21edog=";
                };
                src = inputs.seerr-oidc;
                version = "oidc-${inputs.seerr-oidc.shortRev}";
              });
              port = servicePort;
            };
            environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
              directories = [
                {
                  directory = serviceDir;
                  mode = "0700";
                }
              ];
            };
            nodes = lib.mkMerge [
              {
                ${idmServer} = confLib.mkKanidmOidcSystem {
                  inherit kanidmSopsFile serviceDomain serviceName;
                  originUrl = [
                    "https://${serviceDomain}/login"
                    "https://${serviceDomain}/profile/settings/linked-accounts"
                  ];
                };
              }
              {
                ${webProxy}.services.nginx = confLib.genNginx {
                  inherit
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
                    inherit serviceDomain serviceName servicePort;
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
    }

  ;
}
