{
  flake-file.inputs.copyparty = {
    inputs = {
      flake-utils.follows = "flake-utils";
      nixpkgs.follows = "nixpkgs";
    };
    url = "github:9001/copyparty/hovudstraum";
  };

  flake.modules.nixos.copyparty =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? copyparty) [
        inputs.copyparty.nixosModules.default
        (
          {
            self,
            config,
            lib,
            confLib,
            globals,
            ...
          }:
          let
            inherit
              (confLib.gen {
                name = "copyparty";
                port = 3923;
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

            inherit (config.swarselsystems) mainUser sopsFile;

            dataDir = "/sync/copyparty";
            cacheDir = "/var/cache/copyparty";
            stateDir = "/var/lib/copyparty";
          in
          {
            swarselsystems.enabledServerModules = [ "copyparty" ];
            topology.self.services.${serviceName} = {
              icon = "${self}/files/topology-images/${serviceName}.png";
              info = "https://${serviceDomain}";
              name = lib.swarselsystems.toCapitalized serviceName;
            };
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
              monitoring.http = confLib.mkHttpMonitoring {
                inherit serviceName servicePort;
                expectedBodyRegex = "copyparty";
              };
              networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
            };
            sops.secrets = {
              copyparty-guest-password = {
                inherit sopsFile;
                group = serviceGroup;
                mode = "0400";
                owner = serviceUser;
              };
              copyparty-password = {
                inherit sopsFile;
                group = serviceGroup;
                mode = "0400";
                owner = serviceUser;
              };
            };
            users.persistentIds.${serviceName} = confLib.mkIds 945;
            services.${serviceName} = {
              enable = true;
              accounts = {
                ${mainUser}.passwordFile = config.sops.secrets.copyparty-password.path;
                guest.passwordFile = config.sops.secrets.copyparty-guest-password.path;
              };
              group = serviceGroup;
              settings = {
                hist = cacheDir;
                i = "0.0.0.0";
                no-reload = true;
                p = servicePort;
                rproxy = 1;
                xff-src = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".cidrv4;
              };
              user = serviceUser;
              volumes."/" = {
                access = {
                  rw = "guest";
                  rwmda = mainUser;
                };
                path = dataDir;
              };
            };
            environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
              {
                directory = stateDir;
                group = serviceGroup;
                mode = "0700";
                user = serviceUser;
              }
              {
                directory = cacheDir;
                group = serviceGroup;
                mode = "0700";
                user = serviceUser;
              }
            ];
            nodes =
              let
                uploadProxyConfig = ''
                  proxy_request_buffering off;
                  proxy_buffering off;
                  proxy_read_timeout 1d;
                  proxy_send_timeout 1d;
                '';
              in
              lib.mkMerge [
                {
                  ${webProxy}.services.nginx = confLib.genNginx {
                    inherit
                      serviceAddress
                      serviceDomain
                      serviceName
                      servicePort
                      ;
                    extraConfigLoc = uploadProxyConfig;
                    maxBody = 0;
                    proxyWebsockets = true;
                  };
                }
                {
                  ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                    confLib.genNginx {
                      inherit serviceDomain serviceName servicePort;
                      extraConfig = nginxAccessRules;
                      extraConfigLoc = uploadProxyConfig;
                      maxBody = 0;
                      proxyWebsockets = true;
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
