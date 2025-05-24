{ lib, config, ... }:
{
  options.swarselsystems = {
    modules.optional.hibernation = lib.mkEnableOption "optional amd gpu settings";
    hibernation = {
      offset = lib.mkOption {
        type = lib.types.int;
        default = 0;
      };
      resumeDevice = lib.mkOption {
        type = lib.types.str;
        default = "/dev/disk/by-label/nixos";
      };
    };
  };
  config = lib.mkIf config.swarselsystems.modules.optional.hibernation {
    boot = {
      kernelParams = [
        "resume_offset=${builtins.toString config.swarselsystems.hibernation.offset}"
      ];
      inherit (config.swarselsystems.hibernation) resumeDevice;
    };
  };
}
