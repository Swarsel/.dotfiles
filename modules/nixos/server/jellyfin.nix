{ self, pkgs, lib, config, globals, dns, confLib, ... }:
let
  inherit (confLib.gen { name = "jellyfin"; port = 8096; }) servicePort serviceName serviceUser serviceGroup serviceDomain serviceAddress proxyAddress4 proxyAddress6;
  inherit (confLib.static) isHome isProxied webProxy homeWebProxy idmServer homeProxyIf webProxyIf nginxAccessRules homeServiceAddress;
  kanidmSopsFile = self + "/secrets/kanidm/${config.node.name}.yaml";
in
{
  config = {
    swarselsystems.enabledServerModules = [ "jellyfin" ];

    users = {
      persistentIds.jellyfin = confLib.mkIds 994;
      users.${serviceUser} = {
        extraGroups = [ "video" "render" "users" ];
      };
    };

    sops.secrets.kanidm-jellyfin = { sopsFile = kanidmSopsFile; owner = serviceUser; group = serviceGroup; mode = "0440"; };
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
      services.${serviceName} = {
        domain = serviceDomain;
        inherit proxyAddress4 proxyAddress6 isHome serviceAddress;
        homeServiceAddress = lib.mkIf isHome homeServiceAddress;
      };
      monitoring.http.${serviceName} = {
        url = "http://127.0.0.1:${toString servicePort}/health";
        expectedBodyRegex = "Healthy";
        network = "local-${config.node.name}";
      };
    };

    services.${serviceName} = {
      enable = true;
      user = serviceUser;
      # openFirewall = true; # this works only for the default ports
    };

    environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
      directories = [
        { directory = "/var/lib/${serviceName}"; user = serviceUser; group = serviceGroup; }
        { directory = "/var/cache/${serviceName}"; user = serviceUser; group = serviceGroup; }
      ];
    };

    globals.dns.${globals.services.${serviceName}.baseDomain}.subdomainRecords = {
      "${globals.services.${serviceName}.subDomain}" = dns.lib.combinators.host proxyAddress4 proxyAddress6;
    };

    nodes = {
      ${idmServer} = {
        sops.secrets.kanidm-jellyfin = { sopsFile = kanidmSopsFile; owner = "kanidm"; group = "kanidm"; mode = "0440"; };
        services.kanidm.provision = {
          groups."jellyfin.access" = { };
          systems.oauth2.${serviceName} = {
            displayName = "Jellyfin";
            originUrl = "https://${serviceDomain}/sso/OID/redirect/kanidm";
            originLanding = "https://${serviceDomain}/";
            basicSecretFile = config.sops.secrets.kanidm-jellyfin.path;
            scopeMaps."jellyfin.access" = [
              "openid"
              "email"
              "profile"
            ];
            preferShortUsername = true;
          };
        };
      };
      ${webProxy}.services.nginx = lib.recursiveUpdate
        (confLib.genNginx { inherit serviceAddress servicePort serviceDomain serviceName; maxBody = 0; })
        { virtualHosts.${serviceDomain}.locations."/".X-Frame-Options = "SAMEORIGIN"; };
      ${homeWebProxy}.services.nginx = lib.mkIf isHome (
        lib.recursiveUpdate
          (confLib.genNginx { inherit servicePort serviceDomain serviceName; maxBody = 0; extraConfig = nginxAccessRules; serviceAddress = homeServiceAddress; })
          { virtualHosts.${serviceDomain}.locations."/".X-Frame-Options = "SAMEORIGIN"; }
      );
    };

  };
}
