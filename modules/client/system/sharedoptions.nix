{
  flake.modules.homeManager.sharedoptions =
    {
      config,
      lib,
      nixosConfig ? null,
      ...
    }:
    {
      options.swarselsystems = {
        homeSopsSecrets = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        };
        homeSopsTemplates = lib.mkOption {
          default = { };
          type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.anything);
        };
        monitors = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
        };
      };
      config.swarselsystems = lib.mapAttrs (_: lib.mkDefault) (
        builtins.intersectAttrs config.swarselsystems (nixosConfig.swarselsystems or { })
      );
    };
}
