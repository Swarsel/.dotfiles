{ lib, config, ... }:
{
  services.gnome-keyring = lib.mkIf (!config.swarselsystems.isNixos) {
    enable = true;
  };
}
