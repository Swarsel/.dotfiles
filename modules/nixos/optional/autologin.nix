{ lib, config, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  options.swarselsystems.modules.optional.autologin = lib.mkEnableOption "optional autologin settings";
  config = lib.mkIf config.swarselsystems.modules.optional.autologin {
    services = {
      getty.autologinUser = mainUser;
      greetd.settings.initial_session.user = mainUser;
    };
  };
}
