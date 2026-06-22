{
  flake.modules.nixos.node-roles =
    { lib, config, ... }:
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
