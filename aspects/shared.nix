{
  den = {
    schema = {
      host = _: { };
      conf = { config, lib, ... }: {
        options = {
          isPublic = lib.mkEnableOption "mark this as a public config (= without secrets)";
          isMicroVM = lib.mkEnableOption "mark this config as a microvm";
          mainUser = lib.mkOption {
            type = lib.types.str;
            default = "swarsel";
          };
          node = {
            secretsDir = lib.mkOption {
              description = "Path to the secrets directory for this node.";
              type = lib.types.path;
              default = ../hosts/${config.class}/${config.system}/${config.name}/secrets;
            };
            configDir = lib.mkOption {
              description = "Path to the base directory for this node.";
              type = lib.types.path;
              default = ../hosts/${config.class}/${config.system}/${config.name};
            };
            lockFromBootstrapping = lib.mkOption {
              description = "Whether this host should be marked to not be bootstrapped again using swarsel-bootstrap.";
              type = lib.types.bool;
              default = true;
            };
          };
        };
      };
    };
  };
}
