{
  flake-file.inputs.copyparty = {
    url = "github:9001/copyparty/hovudstraum";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.copyparty =
    { inputs, lib, ... }:
    {
      imports = lib.optionals (inputs ? copyparty) [
        inputs.copyparty.nixosModules.default
        (
          {
            self,
            lib,
            config,
            globals,
            confLib,
            ...
          }:
          let
            inherit
              (confLib.gen {
                name = "copyparty";
                port = 3923;
              })
              servicePort
              serviceName
              serviceUser
              serviceGroup
              serviceDomain
              serviceAddress
              proxyAddress4
              proxyAddress6
              ;
            inherit (confLib.static)
              isHome
              webProxy
              homeWebProxy
              homeServiceAddress
              nginxAccessRules
              ;

            inherit (config.swarselsystems) sopsFile mainUser;

            dataDir = "/sync/copyparty";
            cacheDir = "/var/cache/copyparty";
            stateDir = "/var/lib/copyparty";
          in
          {
            swarselsystems.enabledServerModules = [ "copyparty" ];

            users.persistentIds.${serviceName} = confLib.mkIds 945;

            sops.secrets = {
              copyparty-password = {
                inherit sopsFile;
                owner = serviceUser;
                group = serviceGroup;
                mode = "0400";
              };
              copyparty-guest-password = {
                inherit sopsFile;
                owner = serviceUser;
                group = serviceGroup;
                mode = "0400";
              };
            };

            topology.self.services.${serviceName} = {
              name = lib.swarselsystems.toCapitalized serviceName;
              info = "https://${serviceDomain}";
              icon = "${self}/files/topology-images/${serviceName}.png";
            };

            globals = {
              networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
              services = confLib.mkServiceGlobal {
                inherit
                  serviceName
                  serviceDomain
                  proxyAddress4
                  proxyAddress6
                  isHome
                  serviceAddress
                  homeServiceAddress
                  ;
              };
              monitoring.http = confLib.mkHttpMonitoring {
                inherit serviceName servicePort;
                expectedBodyRegex = "copyparty";
              };
              dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };
            };

            services.${serviceName} = {
              enable = true;
              user = serviceUser;
              group = serviceGroup;
              settings = {
                i = "0.0.0.0";
                p = servicePort;
                no-reload = true;
                hist = cacheDir;
                rproxy = 1;
                xff-src = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".cidrv4;
              };
              accounts = {
                ${mainUser}.passwordFile = config.sops.secrets.copyparty-password.path;
                guest.passwordFile = config.sops.secrets.copyparty-guest-password.path;
              };
              volumes = {
                "/" = {
                  path = dataDir;
                  access = {
                    rwmda = mainUser;
                    rw = "guest";
                  };
                };
              };
            };

            environment.persistence."/persist".directories = lib.mkIf config.swarselsystems.isImpermanence [
              {
                directory = stateDir;
                user = serviceUser;
                group = serviceGroup;
                mode = "0700";
              }
              {
                directory = cacheDir;
                user = serviceUser;
                group = serviceGroup;
                mode = "0700";
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
              {
                ${webProxy}.services.nginx = confLib.genNginx {
                  inherit
                    serviceAddress
                    servicePort
                    serviceDomain
                    serviceName
                    ;
                  maxBody = 0;
                  proxyWebsockets = true;
                  extraConfigLoc = uploadProxyConfig;
                };
                ${homeWebProxy}.services.nginx = lib.mkIf isHome (
                  confLib.genNginx {
                    inherit servicePort serviceDomain serviceName;
                    serviceAddress = homeServiceAddress;
                    maxBody = 0;
                    proxyWebsockets = true;
                    extraConfig = nginxAccessRules;
                    extraConfigLoc = uploadProxyConfig;
                  }
                );
              };
          }
        )
      ];
    };
}
