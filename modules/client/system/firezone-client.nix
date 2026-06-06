{
  flake.modules.nixos.firezone-client = { config, confLib, ... }:
    let
      inherit (config.swarselsystems) mainUser;
    in
    {
      config = {

        users.persistentIds.firezone-client = confLib.mkIds 955;

        services.firezone.gui-client = {
          enable = true;
          inherit (config.node) name;
          allowedUsers = [ mainUser ];
        };
      };
    };
}
