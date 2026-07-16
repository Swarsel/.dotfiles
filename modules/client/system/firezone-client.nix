{
  flake.modules.nixos.firezone-client =
    { config, confLib, ... }:
    let
      inherit (config.swarselsystems) mainUser;
    in
    {
      config = {

        users.persistentIds.firezone-client = confLib.mkIds 955;
        services.firezone.gui-client = {
          inherit (config.node) name;
          enable = true;
          allowedUsers = [ mainUser ];
        };
      };
    };
}
