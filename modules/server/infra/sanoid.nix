{
  flake.modules.nixos.sanoid =
    {
      root,
      config,
      lib,
      ...
    }:
    let
      inherit (config.swarselsystems.server.sanoid) datasets;
      retentionFor =
        dataset:
        if dataset.replica then
          {
            daily = 30;
            hourly = 48;
            monthly = 6;
          }
        else
          {
            daily = 7;
            hourly = 24;
            monthly = 0;
          };
    in
    {
      options.swarselsystems.server.sanoid.datasets = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.replica = lib.mkOption {
              default = false;
              description = "Whether this dataset only receives snapshots instead of taking its own.";
              type = lib.types.bool;
            };
          }
        );
      };
      config = {
        swarselsystems.enabledServerModules = [ "sanoid" ];
        topology.self.services = lib.mapAttrs' (
          name: dataset:
          lib.nameValuePair "sanoid-${lib.replaceStrings [ "/" ] [ "-" ] name}" {
            details.retention.text = lib.concatStringsSep ", " (
              lib.mapAttrsToList (period: count: "${toString count} ${period}") (retentionFor dataset)
            );
            icon = root "files/topology-images/openzfs.png";
            info = if dataset.replica then "${name} (replica)" else name;
            name = "Sanoid snapshots";
          }
        ) datasets;
        services.sanoid = {
          enable = true;
          datasets = lib.mapAttrs (
            _: dataset:
            {
              autoprune = true;
              autosnap = !dataset.replica;
              recursive = true;
            }
            // retentionFor dataset
          ) datasets;
        };
      };
    };
}
