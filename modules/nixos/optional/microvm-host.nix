{ lib, config, ... }:
{
  options = {
    swarselmodules.optional.microvmHost = lib.mkEnableOption "optional microvmHost settings";
  };
  # imports = [
  #   inputs.microvm.nixosModules.host
  # ];

  config = lib.mkIf (config.guests != { }) {

    microvm = {
      hypervisor = lib.mkDefault "qemu";
    };
  };
}
