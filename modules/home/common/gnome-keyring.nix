{ lib, config, ... }:
{
  options.swarselsystems.modules.gnome-keyring = lib.mkEnableOption "gnome keyring settings";
  config = lib.mkIf config.swarselsystems.modules.gnome-keyring {
    services.gnome-keyring = lib.mkIf (!config.swarselsystems.isNixos) {
      enable = true;
    };
  };
}
