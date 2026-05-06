{ lib, config, ... }:
{
  config = {
    swarselsystems.enabledHomeModules = [ "gnome-keyring" ];
    services.gnome-keyring = lib.mkIf (!config.swarselsystems.isNixos) {
      enable = true;
    };
  };
}
