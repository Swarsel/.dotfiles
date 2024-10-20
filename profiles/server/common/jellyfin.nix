{ pkgs, lib, config, ... }:
{
  config = lib.mkIf config.swarselsystems.server.jellyfin {
    users.users.jellyfin = {
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
    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      openFirewall = true; # this works only for the default ports
    };

    services.nginx = {
      virtualHosts = {
        "screen.swarsel.win" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8096";
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
