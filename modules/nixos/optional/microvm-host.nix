{ lib, config, ... }:
{
  options.swarselmodules.optional.microvmHost = lib.mkEnableOption "optional microvmHost settings";
  # imports = [
  #   inputs.microvm.nixosModules.host
  # ];

  config = lib.mkIf (config.swarselmodules.optional.microvmHost && config.swarselsystems.withMicroVMs) {

    microvm = {
      hypervisor = lib.mkDefault "qemu";
    };
  };

}
