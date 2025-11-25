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
        description = "Node Name.";
        type = lib.types.str;
      };
      lockFromBootstrapping = lib.mkOption {
        description = "Whether this host should be marked to not be bootstrapped again using swarsel-bootstrap.";
        type = lib.types.bool;
      };
    };
  };
}
