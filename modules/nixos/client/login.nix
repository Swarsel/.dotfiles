{ lib, config, pkgs, ... }:
{
  options.swarselmodules.login = lib.mkEnableOption "login config";
  config = lib.mkIf config.swarselmodules.login {
    services.greetd = {
      enable = true;
      settings = {
        initial_session.command = "sway";
        default_session.command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --user-menu \
            --cmd sway
        '';
      };
    };

    environment.etc."greetd/environments".text = ''
      sway
    '';
  };
}
