{ lib, config, ... }:
let
  moduleName = "uwsm";
in
{
  options.swarselmodules.${moduleName} = lib.mkEnableOption "${moduleName} settings";
  config = lib.mkIf config.swarselmodules.${moduleName} {
    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        sway = {
          prettyName = "Sway";
          comment = "Sway compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/sway";
        };
        niri = lib.mkIf (config.swarselmodules ? niri) {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/niri-session";
        };
      };
    };
  };
}
