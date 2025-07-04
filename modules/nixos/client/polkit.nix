{ lib, config, minimal, ... }:
{
  options.swarselsystems.modules.security = lib.mkEnableOption "security config";
  config = lib.mkIf config.swarselsystems.modules.security {

    security = {
      pam.services = lib.mkIf (!minimal) {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        swaylock.u2fAuth = true;
        swaylock.fprintAuth = false;
      };
      polkit.enable = lib.mkIf (!minimal) true;

      sudo.extraConfig = ''
        Defaults    env_keep+=SSH_AUTH_SOCK
      '' + lib.optionalString (!minimal) ''
        Defaults    env_keep+=XDG_RUNTIME_DIR
        Defaults    env_keep+=WAYLAND_DISPLAY
      '';
    };
  };
}
