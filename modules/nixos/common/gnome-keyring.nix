{ lib, config, ... }:
{
  options.swarselsystems.modules.gnome-keyring = lib.mkEnableOption "gnome-keyring config";
  config = lib.mkIf config.swarselsystems.modules.gnome-keyring {
    services.gnome.gnome-keyring = {
      enable = true;
    };

    programs.seahorse.enable = true;
  };
}
