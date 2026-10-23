{
  flake.modules.nixos.btrfs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.swarselsystems) isBtrfs isLaptop;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "btrfs" ];
        services.btrfs.autoScrub = lib.mkIf isBtrfs {
          enable = true;
          interval = "monthly";
        };
        boot.supportedFilesystems = lib.mkIf isBtrfs [ "btrfs" ];
        systemd = lib.mkIf isBtrfs {
          services.btrfs-balance = {
            serviceConfig = {
              ExecStart = "${lib.getExe' pkgs.btrfs-progs "btrfs"} balance start -dusage=50 -musage=30 /";
              IOSchedulingClass = "idle";
              Nice = 19;
              Type = "oneshot";
            };
            unitConfig.ConditionACPower = lib.mkIf isLaptop true;
          };
          timers.btrfs-balance = {
            timerConfig = {
              OnCalendar = "Sun 04:00";
              Persistent = true;
            };
            wantedBy = [ "timers.target" ];
          };
        };
      };
    };
}
