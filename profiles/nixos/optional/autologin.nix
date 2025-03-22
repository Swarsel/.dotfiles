{ config, ... }:
let
  inherit (config.swarselsystems) mainUser;
in
{
  services = {
    getty.autologinUser = mainUser;
    greetd.settings.initial_session.user = mainUser;
  };
}
