{
  flake.modules.nixos.jellyfin =
    {
      self,
      config,
      lib,
      pkgs,
      confLib,
      ...
    }:
    let
      inherit
        (confLib.gen {
          name = "jellyfin";
          port = 8096;
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
        idmServer
        isHome
        nginxAccessRules
        webProxy
        ;
      kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "jellyfin" ];
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
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = "Healthy";
            path = "/health";
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        sops.secrets.kanidm-jellyfin = {
          group = serviceGroup;
          mode = "0440";
          owner = serviceUser;
          sopsFile = kanidmSopsFile;
        };
        users = {
          users.${serviceUser}.extraGroups = [
            "video"
            "render"
            "users"
          ];
          persistentIds.jellyfin = confLib.mkIds 994;
        };
        services.${serviceName} = {
          enable = true;
          user = serviceUser;
          # openFirewall = true; # this works only for the default ports
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
            {
              directory = "/var/cache/${serviceName}";
              group = serviceGroup;
              user = serviceUser;
            }
          ];
        };
        # nixpkgs.config.packageOverrides = pkgs: {
        #   intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
        # };
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver # LIBVA_DRIVER_NAME=iHD
            # intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
            libva-vdpau-driver
            libvdpau-va-gl
          ];
        };
        nodes = lib.mkMerge [
          {
            ${idmServer} = confLib.mkKanidmOidcSystem {
              inherit kanidmSopsFile serviceDomain serviceName;
              originUrl = "https://${serviceDomain}/sso/OID/redirect/kanidm";
            };
          }
          {
            ${webProxy}.services.nginx = lib.recursiveUpdate (confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 0;
            }) { virtualHosts.${serviceDomain}.locations."/".X-Frame-Options = "SAMEORIGIN"; };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              lib.recursiveUpdate (confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }) { virtualHosts.${serviceDomain}.locations."/".X-Frame-Options = "SAMEORIGIN"; }
            );
          }
        ];

      };
    }

  ;
}
