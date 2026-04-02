{
  den = {
    schema.conf = { lib, ... }: {
      options = {
        isPublic = lib.mkEnableOption "mark this as a public config (= without secrets)";
        isMicroVM = lib.mkEnableOption "mark this config as a microvm";
        mainUser = lib.mkOption {
          type = lib.types.str;
          default = "swarsel";
        };
      };
    };
  };
}
