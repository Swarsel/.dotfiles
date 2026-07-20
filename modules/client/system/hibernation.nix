{
  flake.modules.nixos.hibernation = { config, lib, ... }: {
    options.swarselsystems.hibernation = {
      offset = lib.mkOption {
        default = 0;
        type = lib.types.int;
      };
      resumeDevice = lib.mkOption {
        default = "/dev/disk/by-label/nixos";
        type = lib.types.str;
      };
    };
    config = {
      boot = {
        inherit (config.swarselsystems.hibernation) resumeDevice;
        kernelParams = [
          "resume_offset=${builtins.toString config.swarselsystems.hibernation.offset}"
          # "mem_sleep_default=deep"
        ];
      };
      powerManagement.enable = true;
      systemd = {
        services."systemd-suspend-then-hibernate".aliases = [ "systemd-suspend.service" ];
        sleep.settings.Sleep = {
          HibernateDelaySec = "120m";
          SuspendState = "freeze";
        };
      };
    };
  };
}
