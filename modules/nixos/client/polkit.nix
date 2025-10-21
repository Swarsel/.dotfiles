{ lib, config, minimal, ... }:
{
  options.swarselmodules.security = lib.mkEnableOption "security config";
  config = lib.mkIf config.swarselmodules.security {

    security = {
      pam.services = lib.mkIf (!minimal) {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        sshd.u2fAuth = false;
        swaylock = {
          u2fAuth = true;
          fprintAuth = false;
        };
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
