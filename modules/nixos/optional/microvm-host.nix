{ config, lib, ... }:
{
  # imports = [
  # inputs.microvm.nixosModules.host
  # ];

  config = lib.mkIf (config.guests != { }) {

    microvm = {
      hypervisor = lib.mkDefault "qemu";
    };
  };
}
