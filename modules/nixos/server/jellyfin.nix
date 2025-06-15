{ pkgs, lib, config, ... }:
let
  serviceDomain = "screen.swarsel.win";
  servicePort = 8096;
  serviceName = "jellyfin";
  serviceUser = "jellyfin";
in
{
  options.swarselsystems.modules.server."${serviceName}" = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselsystems.modules.server."${serviceName}" {
    users.users."${serviceUser}" = {
      extraGroups = [ "video" "render" "users" ];
    };
    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    topology.self.services.jellyfin.info = "https://${serviceDomain}";

    services.jellyfin = {
      enable = true;
      user = serviceUser;
      openFirewall = true; # this works only for the default ports
    };

    nodes.moonside.services.nginx = {
      upstreams = {
        "${serviceName}" = {
          servers = {
            "192.168.1.2:${builtins.toString servicePort}" = { };
          };
        };
      };
      virtualHosts = {
        "${serviceDomain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://${serviceName}";
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
          };
        };
      };
    };
  };

}
