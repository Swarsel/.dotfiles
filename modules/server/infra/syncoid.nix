{
  flake.modules.nixos.syncoid =
    {
      self,
      root,
      config,
      lib,
      confLib,
      ...
    }:
    let
      inherit (config.swarselsystems.server.syncoid) targets;
    in
    {
      imports = [
        self.modules.nixos.sanoid
      ];
      options.swarselsystems.server.syncoid.targets = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.target = lib.mkOption {
              description = "Dataset that receives the snapshots of the to be backed up dataset.";
              type = lib.types.str;
            };
          }
        );
      };
      config = {
        swarselsystems = {
          enabledServerModules = [ "syncoid" ];
          server.sanoid.datasets = lib.mapAttrs' (
            _: target: lib.nameValuePair target.target { replica = true; }
          ) targets;
        };
        topology.self.services = lib.mapAttrs' (
          source: target:
          lib.nameValuePair "syncoid-${lib.replaceStrings [ "/" ] [ "-" ] source}" {
            details.interval.text = config.services.syncoid.interval;
            icon = root "files/topology-images/openzfs.png";
            info = "${source} → ${target.target}";
            name = "Syncoid replication";
          }
        ) targets;
        users.persistentIds.syncoid = confLib.mkIds 933;
        services.syncoid = {
          enable = true;
          commands = lib.mapAttrs (_: target: {
            inherit (target) target;
            extraArgs = [
              "--no-sync-snap"
              "--recvoptions=u"
            ];
            recursive = true;
          }) targets;
          interval = "hourly";
        };
      };
    };
}
