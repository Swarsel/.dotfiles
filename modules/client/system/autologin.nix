{
  flake.modules.nixos.autologin =
    { config, ... }:
    {
      config.services.greetd.settings.initial_session.user = config.swarselsystems.mainUser;
    };
}
