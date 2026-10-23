{
  flake.modules.nixos.podman =
    {
      config,
      lib,
      confLib,
      ...
    }:
    {
      config = {
        swarselsystems.enabledServerModules = [ "podman" ];
        users.persistentIds.podman = confLib.mkIds 969;
        environment.persistence = {
          "/persist".directories =
            lib.mkIf (config.swarselsystems.isImpermanence && !config.swarselsystems.isMicroVM)
              [
                { directory = "/var/lib/containers"; }
              ];
          "/state".directories = lib.mkIf config.swarselsystems.isMicroVM [
            { directory = "/var/lib/containers"; }
          ];
        };
        networking.nftables.firewall = lib.mkIf config.networking.nftables.enable {

          rules = {
            local-to-podman = {
              before = [ "drop" ];
              from = [
                "local"
                "wgProxy"
                "wgHome"
              ];
              to = [ "podman" ];
              verdict = "accept";
            };
            podman-to-internet = lib.mkIf (config.networking.nftables.firewall.zones ? untrusted) {
              before = [ "drop" ];
              from = [ "podman" ];
              to = [ "untrusted" ];
              verdict = "accept";
            };
            podman-to-postgres = lib.mkIf config.services.postgresql.enable {
              allowedTCPPorts = [ config.services.postgresql.settings.port ];
              before = [ "drop" ];
              from = [ "podman" ];
              to = [ "local" ];
            };
          };
          zones.podman.interfaces = [ "podman0" ];
        };
        virtualisation = {
          oci-containers.backend = "podman";
          podman.enable = true;
        };
        systemd.services.podman-network-reload =
          let
            reload = "${lib.getExe config.virtualisation.podman.package} network reload --all";
          in
          lib.mkIf config.networking.nftables.enable {
            after = [ "nftables.service" ];
            partOf = [ "nftables.service" ];
            serviceConfig = {
              ExecReload = reload;
              ExecStart = reload;
              RemainAfterExit = true;
              Type = "oneshot";
            };
            unitConfig.ReloadPropagatedFrom = [ "nftables.service" ];
            wantedBy = [
              "multi-user.target"
              "nftables.service"
            ];
          };

      };
      key = "swarsel/server/podman";
    }

  ;
}
