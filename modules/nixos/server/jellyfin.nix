{ self, pkgs, lib, config, confLib, ... }:
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
      services = confLib.mkServiceGlobal { inherit serviceName serviceDomain proxyAddress4 proxyAddress6 isHome serviceAddress homeServiceAddress; };
      monitoring.http = confLib.mkHttpMonitoring { inherit serviceName servicePort; path = "/health"; expectedBodyRegex = "Healthy"; };
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

    globals.dns = confLib.mkDnsRecord { inherit serviceName proxyAddress4 proxyAddress6; };

    nodes = {
      ${idmServer} = confLib.mkKanidmOidcSystem {
        inherit serviceName serviceDomain kanidmSopsFile;
        originUrl = "https://${serviceDomain}/sso/OID/redirect/kanidm";
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
