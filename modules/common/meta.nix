{
  flake.modules.generic.meta =
    { lib, ... }:
    {
      options = {
        node = {
          arch = lib.mkOption {
            type = lib.types.str;
          };
          configDir = lib.mkOption {
            default = ./.;
            description = "Path to the base directory for this node.";
            type = lib.types.path;
          };
          lockFromBootstrapping = lib.mkOption {
            description = "Whether this host should be marked to not be bootstrapped again using swarsel-bootstrap.";
            type = lib.types.bool;
          };
          name = lib.mkOption {
            type = lib.types.str;
          };
          secretsDir = lib.mkOption {
            default = ./.;
            description = "Path to the secrets directory for this node.";
            type = lib.types.path;
          };
          type = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };
}
