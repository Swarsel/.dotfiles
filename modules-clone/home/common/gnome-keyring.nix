{ lib, config, ... }:
{
  options.swarselmodules.gnome-keyring = lib.mkEnableOption "gnome keyring settings";
  config = lib.mkIf config.swarselmodules.gnome-keyring {
    services.gnome-keyring = lib.mkIf (!config.swarselsystems.isNixos) {
      enable = true;
    };
  };
}
