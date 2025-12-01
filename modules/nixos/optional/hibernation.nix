{ lib, config, ... }:
{
  options.swarselsystems = {
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
  config = {
    boot = {
      kernelParams = [
        "resume_offset=${builtins.toString config.swarselsystems.hibernation.offset}"
        # "mem_sleep_default=deep"
      ];
      inherit (config.swarselsystems.hibernation) resumeDevice;
    };
    systemd.services."systemd-suspend-then-hibernate".aliases = [ "systemd-suspend.service" ];
    powerManagement.enable = true;
    systemd.sleep.extraConfig = ''
      HibernateDelaySec=120m
      SuspendState=freeze
    '';
  };
}
