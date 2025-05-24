{ lib, config, pkgs, ... }:
{
  options.swarselsystems.modules.login = lib.mkEnableOption "login config";
  config = lib.mkIf config.swarselsystems.modules.login {
    services.greetd = {
      enable = true;
      settings = {
        initial_session.command = "sway";
        default_session.command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
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
