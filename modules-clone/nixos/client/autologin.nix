{ lib, config, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  options.swarselmodules.autologin = lib.mkEnableOption "optional autologin settings";
  config = lib.mkIf config.swarselmodules.autologin {
    services = {
      getty.autologinUser = mainUser;
      greetd.settings.initial_session.user = mainUser;
    };
  };
}
