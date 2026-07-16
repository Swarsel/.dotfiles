{
  flake.modules.nixos.node-roles =
    { config, lib, ... }:
    {
      config = {
        globals.general = lib.listToAttrs (
          map (name: {
            inherit name;
            value = config.node.name;
          }) config.swarselsystems.nodeRoles
        );
      };
    }

  ;
}
