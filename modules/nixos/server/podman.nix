{ config, lib, ... }:
let
  serviceName = "podman";
in
{
  options.swarselmodules.server.${serviceName} = lib.mkEnableOption "enable ${serviceName} on server";
  config = lib.mkIf config.swarselmodules.server.${serviceName} {

    virtualisation = {
      podman.enable = true;
      oci-containers.backend = "podman";
    };

    networking.nftables.firewall = lib.mkIf config.networking.nftables.enable {

      zones.podman = {
        interfaces = [ "podman0" ];
      };

      rules = {
        podman-to-postgres = lib.mkIf config.services.postgresql.enable {
          from = [ "podman" ];
          to = [ "local" ];
          before = [ "drop" ];
          allowedTCPPorts = [ config.services.postgresql.settings.port ];
        };

        local-to-podman = {
          from = [ "local" "wgProxy" "wgHome" ];
          to = [ "podman" ];
          before = [ "drop" ];
          verdict = "accept";
        };
      };
    };

  };
}
