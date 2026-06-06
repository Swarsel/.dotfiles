{
  flake.modules.nixos.autologin = { config, ... }:
    let
      inherit (config.swarselsystems) mainUser;
    in
    {
      config = {
        services = {
          getty.autologinUser = mainUser;
          greetd.settings.initial_session.user = mainUser;
        };
      };
    };
}
