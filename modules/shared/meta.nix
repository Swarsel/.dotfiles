{ lib, ... }:
{
  options = {
    node = {
      secretsDir = lib.mkOption {
        description = "Path to the secrets directory for this node.";
        type = lib.types.path;
        default = ./.;
      };
      name = lib.mkOption {
        type = lib.types.str;
      };
      arch = lib.mkOption {
        type = lib.types.str;
      };
      type = lib.mkOption {
        type = lib.types.str;
      };
      lockFromBootstrapping = lib.mkOption {
        description = "Whether this host should be marked to not be bootstrapped again using swarsel-bootstrap.";
        type = lib.types.bool;
      };
    };
  };
}
